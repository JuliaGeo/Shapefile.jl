
# Shapefile Polygons are actually MultiPolygons made up of unsorted rings.
# To handle this we add additional types not in the Shapefile specification.
# LinearRing represents individual rings while `SubPolygon` is a single external
# ring and n internal rings (holes).
# Generating polygons is expensive - it must be calculated if they are
# exterior or interior, and which interiors are inside which exteriors

struct LinearRing{P,Z,M} <: AbstractVector{P}
    xy::SubArray{Point,1,Vector{Point},Tuple{UnitRange{Int64}},true}
    z::Z
    m::M
end
LinearRing{P}(xy, z::Z, m::M) where {P,Z,M} = LinearRing{P,Z,M}(xy, z, m)
LinearRing{P}(xy; z=nothing, m=nothing) where {P} = LinearRing{P}(xy, z, m)

GI.isgeometry(::Type{<:LinearRing}) = true
GI.geomtrait(::LinearRing) = GI.LinearRingTrait()
GI.ncoord(::GI.LinearRingTrait, lr::LinearRing{P}) where {P} = _ncoord(P)
GI.ngeom(::GI.LinearRingTrait, lr::LinearRing) = length(lr)

GI.getgeom(::GI.LinearRingTrait, lr::LinearRing, i::Integer) = lr[i]

Base.@propagate_inbounds Base.getindex(lr::LinearRing{Point}, i) =
    lr.xy[i]
Base.@propagate_inbounds Base.getindex(lr::LinearRing{PointM}, i) =
    PointM(lr.xy[i], lr.m[i])
Base.@propagate_inbounds Base.getindex(lr::LinearRing{PointZ}, i) =
    PointZ(lr.xy[i], lr.z[i], lr.m[i])
Base.size(lr::LinearRing) = (length(lr),)
Base.length(lr::LinearRing) = length(lr.xy)

struct SubPolygon{L<:LinearRing} <: AbstractVector{L}
    rings::Vector{L}
end
GI.isgeometry(::Type{<:SubPolygon}) = true
GI.geomtrait(::SubPolygon) = GI.PolygonTrait()
GI.is3d(::GI.PolygonTrait, p::SubPolygon) = GI.is3d(first(p))
GI.ismeasured(::GI.PolygonTrait, p::SubPolygon) = GI.measures(first(p))
GI.ncoord(::GI.PolygonTrait, ::SubPolygon{<:LinearRing{P}}) where {P} = _ncoord(P)
GI.ngeom(::GI.PolygonTrait, sp::SubPolygon) = length(sp)
Base.@propagate_inbounds GI.getgeom(::GI.PolygonTrait, sp::SubPolygon, i::Integer) =
    getindex(sp, i)

Base.parent(p::SubPolygon) = p.rings
Base.@propagate_inbounds Base.getindex(p::SubPolygon, i) =
    getindex(parent(p), i)
Base.length(p::SubPolygon) = length(parent(p))
Base.size(p::SubPolygon) = (length(p),)
Base.push!(p::SubPolygon, x) = Base.push!(parent(p), x)


abstract type AbstractPolygon{T} <: AbstractShape end

_hasparts(::GI.MultiPolygonTrait) = true
_hasparts(::GI.PolygonTrait) = true

# Shapefile polygons are OGC multipolygons
GI.geomtrait(geom::AbstractPolygon) = GI.MultiPolygonTrait()
GI.nring(::GI.MultiPolygonTrait, geom::AbstractPolygon) = length(geom.parts)
GI.ncoord(::GI.MultiPolygonTrait, geom::AbstractPolygon{T}) where {T} = _ncoord(T)
GI.npoint(::GI.MultiPolygonTrait, geom::AbstractPolygon) = length(geom.points)
function GI.ngeom(::GI.MultiPolygonTrait, geom::AbstractPolygon)
    n = 0
    for ring in GI.getring(geom)
        if _isclockwise(ring)
            n += 1
        end
    end
    return n
end


function GI.getring(t::GI.MultiPolygonTrait, geom::AbstractPolygon)
    return (GI.getring(t, geom, i) for i in eachindex(geom.parts))
end
function GI.getring(::GI.MultiPolygonTrait, geom::AbstractPolygon{P}, i::Integer) where {P}
    pa = geom.parts
    range = pa[i]+1:(i == lastindex(pa) ? lastindex(geom.points) : pa[i+1])
    xy = view(geom.points, range)
    m = P <: Union{PointM,PointZ} ? view(geom.measures, range) : nothing
    z = P <: Union{PointZ} ? view(geom.zvalues, range) : nothing
    LinearRing{P}(xy, z, m)
end

# Warning: getgeom is very slow for a Shapefile.
# If you don't need exteriors and holes to be separated, use `getring`.
function GI.getgeom(::GI.MultiPolygonTrait, geom::AbstractPolygon, i::Integer)
    if length(geom.indexcache) == 0
        _build_cache!(geom)
    end
    indices = geom.indexcache[i]
    rings = GI.getring.((GI.MultiPolygonTrait(),), (geom,), indices)
    return SubPolygon(rings)
end
function GI.getgeom(::GI.MultiPolygonTrait, geom::AbstractPolygon{T}) where {T}
    if length(geom.indexcache) == 0
        _build_cache!(geom)
    end
    return map(geom.indexcache) do indices
        SubPolygon(GI.getring.((geom,), indices)) 
    end
end

# Build the indexcache for a Polygon
function _build_cache!(geom::AbstractPolygon)
    hole_inds = Int[]
    indexcache = geom.indexcache
    for (i, ring) in enumerate(GI.getring(geom))
        if _isclockwise(ring)
            push!(indexcache, [i]) # create new polygon
        else
            push!(hole_inds, i)
        end
    end
    if length(hole_inds) > 0
        # Ignore Z dimension for extents, this is 2.5D
        extents = map(r -> GI.extent(r)[(:X, :Y)], GI.getring(geom))
        for h in hole_inds
            hole = GI.getring(geom, h)
            length(hole) > 0 || continue
            hole_extent = extents[h]
            found = false
            for ic in indexcache
                e = ic[1]
                exterior = GI.getring(geom, e)
                if Extents.intersects(hole_extent, extents[e]) && _inring(hole[1], exterior)
                    push!(ic, h)
                    found = true
                    break
                end
            end
            if !found
                # The hole is not inside any ring, so make it a polygon.
                # This is not intended behaviour but ESRI docs call it
                # a "Dirty" ring. So it is a thing in the wild.
                push!(indexcache, [h])
            end
        end
    end
    return geom
end

function _inring(pt::AbstractPoint, ring::LinearRing)
    length(ring) > 2 || return false
    isinside = @inbounds _intersects(pt, ring[1], ring[end])
    # This loop is 80% of Polygon read time
    for k = 2:length(ring)
        intersects = @inbounds _intersects(pt, ring[k], ring[k-1])
        isinside = intersects ? !isinside : isinside
    end
    return isinside
end

function _isclockwise(ring)
    clockwise_test = 0.0
    for i in 1:length(ring)-1
        prev = @inbounds ring[i]
        cur = @inbounds ring[i + 1]
        clockwise_test += (cur.x - prev.x) * (cur.y + prev.y)
    end
    clockwise_test > 0
end

function _intersects(pt, i, j)
    (i.y >= pt.y) != (j.y >= pt.y) &&
    (pt.x <= (j.x - i.x) * (pt.y - i.y) / (j.y - i.y) + i.x)
end

# TODO add this to `Extents.union` for any `Tuple/AbstractArray` point
function _union(extent::Extents.Extent, point::Tuple)
    X = min(extent.X[1], point[1]), max(extent.X[2], point[1])
    Y = min(extent.Y[1], point[2]), max(extent.Y[2], point[2])
    return Extents.Extent(; X, Y)
end


"""
    Polygon <: AbstractPolygon

Represents a Polygon from a shape file.

# Fields
- `points`: a `Vector` of [`Point`](@ref) represents a one or multiple closed areas.
- `parts`: a `Vector` of `Int32` indicating the polygon each point belongs to.
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GI.bbox`.
"""
struct Polygon <: AbstractPolygon{Point}
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    indexcache::Vector{Vector{Int}}
end
Polygon(MBR, parts, points) = Polygon(MBR, parts, points, Vector{Int}[])

Base.show(io::IO, p::Polygon) = print(io, "Polygon(", length(p.points), " Points)")

function Base.read(io::IO, ::Type{Polygon})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = _readparts(io, numparts)
    points = _readpoints(io, numpoints)
    Polygon(box, parts, points)
end

Base.:(==)(p1::Polygon, p2::Polygon) = (p1.parts == p2.parts) && (p1.points == p2.points)

"""
    PolygonM <: AbstractPolygon

Represents a polygon from a shape file

# Fields
- `points`: a `Vector` of [`Point`](@ref) represents a one or multiple closed areas.
- `parts`: a `Vector` of `Int32` indicating the polygon each point belongs to.
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GI.bbox`.
- `measures`: holds values from each point.
"""
struct PolygonM <: AbstractPolygon{PointM}
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    mrange::Interval
    measures::Vector{Float64}
    indexcache::Vector{Vector{Int}}
end
PolygonM(MBR, parts, points, mrange, measures) =
    PolygonM(MBR, parts, points, mrange, measures, Vector{Int}[])


Base.:(==)(p1::PolygonM, p2::PolygonM) =
    (p1.parts == p2.parts) && (p1.points == p2.points) && (p1.measures == p2.measures)

function Base.read(io::IO, ::Type{PolygonM})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = _readparts(io, numparts)
    points = _readpoints(io, numpoints)
    mrange, measures = _readm(io, numpoints)
    PolygonM(box, parts, points, mrange, measures)
end

"""
    PolygonZ <: AbstractPolygon

A three dimensional polygon from a shape file.

# Fields
- `points`: a `Vector` of [`Point`](@ref) represents a one or multiple closed areas.
- `parts`: a `Vector` of `Int32` indicating the polygon each point belongs to.
- `zvalues`: a `Vector` of `Float64` representing the z dimension values.
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GI.bbox`.
- `measures`: holds values from each point.
"""
struct PolygonZ <: AbstractPolygon{PointZ}
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    zrange::Interval
    zvalues::Vector{Float64}
    mrange::Interval
    measures::Vector{Float64}
    indexcache::Vector{Vector{Int}}
end
PolygonZ(MBR, parts, points, zrange, zvalues, mrange, measures) =
    PolygonZ(MBR, parts, points, zrange, zvalues, mrange, measures, Vector{Int}[])

Base.:(==)(p1::PolygonZ, p2::PolygonZ) =
    (p1.parts == p2.parts) && (p1.points == p2.points) && (p1.zvalues == p2.zvalues) && (p1.measures == p2.measures)

function Base.read(io::IO, ::Type{PolygonZ})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = _readparts(io, numparts)
    points = _readpoints(io, numpoints)
    zrange, zvalues = _readz(io, numpoints)
    mrange, measures = _readm(io, numpoints)
    PolygonZ(box, parts, points, zrange, zvalues, mrange, measures)
end
