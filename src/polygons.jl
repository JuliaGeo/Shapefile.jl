
# Shapefiles Polygons are actually MultiPolygons Made up of unsorted rings.
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
GI.ncoord(lr::LinearRing{P}) where {P} = _ncoord(P)
GI.ngeom(::GI.LinearRingTrait, lr::LinearRing) = length(lr)

GI.getgeom(::GI.LinearRingTrait, lr::LinearRing{Point}, i::Integer) = lr.xy[i]
GI.getgeom(::GI.LinearRingTrait, lr::LinearRing{PointM}, i::Integer) =
    PointM(lr.xy[i], lr.m[i])
GI.getgeom(::GI.LinearRingTrait, lr::LinearRing{PointZ}, i::Integer) =
    PointZ(lr.xy[i], lr.z[i], lr.m[i])

Base.parent(lr::LinearRing) = lr.xy
Base.getindex(lr::LinearRing, i) = getindex(parent(lr), i)
Base.size(p::LinearRing) = (length(p),)
Base.length(lr::LinearRing) = length(parent(lr))

struct SubPolygon{L<:LinearRing} <: AbstractVector{L}
    rings::Vector{L}
end
GI.isgeometry(::Type{<:SubPolygon}) = true
GI.geomtrait(::SubPolygon) = GI.PolygonTrait()
GI.ncoord(::GI.PolygonTrait, ::SubPolygon{LinearRing{P}}) where {P} = _ncoord(P)
GI.ngeom(::GI.PolygonTrait, sp::SubPolygon) = length(sp)
GI.getgeom(::GI.PolygonTrait, sp::SubPolygon, i::Integer) = getindex(sp, i)

Base.parent(p::SubPolygon) = p.rings
Base.getindex(p::SubPolygon, i) = getindex(parent(p), i)
Base.length(p::SubPolygon) = length(parent(p))
Base.size(p::SubPolygon) = (length(p),)
Base.push!(p::SubPolygon, x) = Base.push!(parent(p), x)


abstract type AbstractPolygon{T} <: AbstractShape end

# Shapefile polygons are OGC multipolygons
GI.geomtrait(geom::AbstractPolygon) = GI.MultiPolygonTrait()
GI.nring(::GI.MultiPolygonTrait, geom::AbstractPolygon) = length(geom.parts)
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
GI.getgeom(::GI.MultiPolygonTrait, geom::AbstractPolygon, i::Integer) = collect(GI.getgeom(geom))[i]
function GI.getgeom(::GI.MultiPolygonTrait, geom::AbstractPolygon{T}) where {T}
    r1 = GI.getring(geom, 1)
    polygons = SubPolygon{typeof(r1)}[]
    holes = typeof(r1)[]
    for ring in GI.getring(geom)
        if _isclockwise(ring)
            push!(polygons, SubPolygon([ring])) # create new polygon
        else
            push!(holes, ring)
        end
    end
    for hole in holes
        found = false
        for i = 1:length(polygons)
            if _inring(hole[1], polygons[i][1])
                push!(polygons[i], hole)
                found = true
                break
            end
        end
        if !found
            # TODO: does this follow the spec? this should not happen with a correct file.
            push!(polygons, SubPolygon([hole])) # hole is not inside any ring; make it a polygon
        end
    end
    return polygons
end

function _inring(pt::Point, ring::LinearRing)
    intersect(i, j) =
        (i.y >= pt.y) != (j.y >= pt.y) &&
        (pt.x <= (j.x - i.x) * (pt.y - i.y) / (j.y - i.y) + i.x)
    isinside = intersect(ring[1], ring[end])
    for k = 2:length(ring)
        isinside = intersect(ring[k], ring[k-1]) ? !isinside : isinside
    end
    return isinside
end

function _isclockwise(ring)
    clockwise_test = 0.0
    for i in 1:GI.npoint(ring)-1
        prev = ring[i]
        cur = ring[i + 1]
        clockwise_test += (cur.x - prev.x) * (cur.y + prev.y)
    end
    clockwise_test > 0
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
end

Base.show(io::IO, p::Polygon) = print(io, "Polygon(", length(p.points), " Points)")

function Base.read(io::IO, ::Type{Polygon})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    Polygon(box, parts, points)
end

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
end

function Base.read(io::IO, ::Type{PolygonM})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    mrange = read(io, Interval)
    measures = Vector{Float64}(undef, numpoints)
    read!(io, measures)
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
end

function Base.read(io::IO, ::Type{PolygonZ})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    zrange = read(io, Interval)
    zvalues = Vector{Float64}(undef, numpoints)
    read!(io, zvalues)
    mrange = read(io, Interval)
    measures = Vector{Float64}(undef, numpoints)
    read!(io, measures)
    PolygonZ(box, parts, points, zrange, zvalues, mrange, measures)
end
