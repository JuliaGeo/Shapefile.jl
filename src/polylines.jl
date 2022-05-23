
struct LineString{P,Z,M} <: AbstractVector{P}
    xy::SubArray{Point,1,Vector{Point},Tuple{UnitRange{Int64}},true}
    z::Z
    m::M
end
LineString{P}(xy, z::Z, m::M) where {P,Z,M} = LineString{P,Z,M}(xy, z, m)
LineString{P}(xy; z=nothing, m=nothing) where {P} = LineString{P}(xy, z, m)

GI.isgeometry(::Type{<:LineString}) = true
GI.geomtrait(::LineString) = GI.LineStringTrait()
GI.ncoord(lr::LineString{T}) where {T} = _ncoord(T)
GI.ngeom(::GI.LineStringTrait, lr::LineString) = length(lr)
# GI.getgeom(::GI.LineStringTrait, lr::LineString) = (getindex(lr, i) for i in 1:ngeom(lr))
GI.getgeom(::GI.LineStringTrait, lr::LineString, i::Integer) = getindex(lr, i)

Base.parent(lr::LineString) = lr.xy
Base.size(p::LineString) = (length(p),)
Base.length(lr::LineString) = length(parent(lr))
Base.getindex(lr::LineString{Point}, i) = lr.xy[i]
Base.getindex(lr::LineString{PointM}, i) = PointM(lr.xy[i], lr.m[i])
Base.getindex(lr::LineString{PointZ}, i) = PointZ(lr.xy[i], lr.z[i], lr.m[i])


abstract type AbstractPolyline{T} <: AbstractShape end

_pointtype(::Type{<:AbstractPolyline{T}}) where T = T

Base.convert(::Type{T}, ::GI.MultiLineStringTrait, geom) where T<:AbstractPolyline =
    T(_convertparts(_pointtype(T), geom)...)

GI.geomtrait(::AbstractPolyline) = GI.MultiLineStringTrait()
GI.ngeom(::GI.MultiLineStringTrait, geom::AbstractPolyline) = length(geom.parts)
GI.ncoord(::GI.MultiLineStringTrait, ::AbstractPolyline{T}) where {T} = _ncoord(T)
function GI.getgeom(::GI.MultiLineStringTrait, geom::AbstractPolyline{P}, i::Integer) where {P}
    range = if i < GI.ngeom(geom)
        # The linestring is the points between two parts
        # C integers start at zero so we add 1 to the range start
        (geom.parts[i]+1):(geom.parts[i+1])
    else
        # For the last inestring use the vector lastindex as the last point
        (geom.parts[i]+1):lastindex(geom.points)
    end
    return LineString(geom, range)
end

"""
    Polyline <: AbstractPolyline

Represents a single or multiple polylines from a shape file.

# Fields
- `points`: a `Vector` of [`Point`]() represents a one or multiple lines.
- `parts`: a `Vector` of `Int32` indicating the line each point belongs to.
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GeoInterface.bbox`.
"""
struct Polyline <: AbstractPolyline{Point}
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
end

function Base.read(io::IO, ::Type{Polyline})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = _readparts(io, numparts)
    points = _readpoints(io, numpoints)
    Polyline(box, parts, points)
end

LineString(geom::Polyline, range) = @views LineString{Point}(geom.points[range])

"""
    PolylineM <: AbstractPolyline

Polyline from a shape file, with measures.

# Fields
- `points`: a `Vector` of [`Point`](@ref) represents a one or multiple lines.
- `parts`: a `Vector` of `Int32` indicating the line each point belongs to.
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GeoInterface.bbox`.
- `measures`: holds values from each point.
"""
struct PolylineM <: AbstractPolyline{PointM}
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    mrange::Interval
    measures::Vector{Float64}
end

LineString(geom::PolylineM, range) =
    @views LineString{PointM}(geom.points[range]; m=geom.measures[range])

function Base.read(io::IO, ::Type{PolylineM})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = _readparts(io, numparts)
    points = _readpoints(io, numpoints)
    mrange, measures = _readm(io, numpoints)
    PolylineM(box, parts, points, mrange, measures)
end

"""
    PolylineZ <: AbstractPolyline

Three dimensional polyline of from a shape file.

# Fields
- `points`: a `Vector` of [`Point`](@ref) represents a one or multiple lines.
- `parts`: a `Vector` of `Int32` indicating the line each point belongs to.
- `zvalues`: a `Vector` of `Float64` representing the z dimension values.
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GeoInterface.bbox`.
- `measures`: holds values from each point.
"""
struct PolylineZ <: AbstractPolyline{PointZ}
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    zrange::Interval
    zvalues::Vector{Float64}
    mrange::Interval
    measures::Vector{Float64}
end

LineString(geom::PolylineZ, range) =
    @views LineString{PointZ}(geom.points[range]; z=geom.zvalues[range], m=geom.measures[range])

function Base.read(io::IO, ::Type{PolylineZ})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = _readparts(io, numparts)
    points = _readpoints(io, numpoints)
    zrange, zvalues = _readz(io, numpoints)
    mrange, measures = _readm(io, numpoints)
    PolylineZ(box, parts, points, zrange, zvalues, mrange, measures)
end
