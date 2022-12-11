
abstract type AbstractMultiPoint{T} <: AbstractShape end

_pointtype(::Type{<:AbstractMultiPoint{T}}) where T = T

Base.convert(::Type{T}, ::GI.MultiPointTrait, geom) where T<:AbstractMultiPoint =
    T(_convert(_pointtype(T), geom)...)

GI.geomtrait(::AbstractMultiPoint) = GI.MultiPointTrait()
GI.ngeom(::GI.MultiPointTrait, geom::AbstractMultiPoint) = length(geom.points)
GI.ncoord(::GI.MultiPointTrait, geom::AbstractMultiPoint{T}) where {T} = _ncoord(T)
GI.npoint(::GI.MultiPointTrait, geom::AbstractMultiPoint) = length(geom.points)

"""
    MultiPoint <: AbstractMultiPoint

Collection of points, from a shape file.

# Fields
- `points`: a `Vector` of [`Point`](@ref).
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GeoInterface.bbox`.
"""
struct MultiPoint <: AbstractMultiPoint{Point}
    MBR::Rect
    points::Vector{Point}
end

Base.:(==)(p1::MultiPoint, p2::MultiPoint) = p1.points == p2.points

function Base.read(io::IO, ::Type{MultiPoint})
    box = read(io, Rect)
    numpoints = read(io, Int32)
    points = _readpoints(io, numpoints)
    return MultiPoint(box, points)
end

GI.getgeom(::GI.MultiPointTrait, geom::MultiPoint, i::Integer) = geom.points[i]


"""
    MultiPointM <: AbstractMultiPoint

Collection of points, from a shape file.

Includes a `measures` field, holding values from each point.

May have a known bounding box, which can be retrieved with `GeoInterface.bbox`.

# Fields
- `points`: a `Vector` of [`Point`](@ref).
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GeoInterface.bbox`.
- `measures`: holds values from each point.
"""
struct MultiPointM <: AbstractMultiPoint{PointM}
    MBR::Rect
    points::Vector{Point}
    mrange::Interval
    measures::Vector{Float64}
end

Base.:(==)(p1::MultiPointM, p2::MultiPointM) =
    (p1.points == p2.points) && (p1.measures == p2.measures)

function Base.read(io::IO, ::Type{MultiPointM})
    box = read(io, Rect)
    numpoints = read(io, Int32)
    points = _readpoints(io, numpoints)
    mrange, measures = _readm(io, numpoints)
    MultiPointM(box, points, mrange, measures)
end

GI.getgeom(::GI.MultiPointTrait, geom::MultiPointM, i::Integer) =
    PointM(geom.points[i], geom.measures[i])

"""
    MultiPointZ <: AbstractMultiPoint

Collection of 3d points, from a shape file.

Includes a `measures` field, holding values from each point.

May have a known bounding box, which can be retrieved with `GeoInterface.bbox`.

# Fields
- `points`: a `Vector` of [`Point`](@ref).
- `zvalues`: a `Vector` of `Float64` representing the z dimension values.
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GeoInterface.bbox`.
- `measures`: holds values from each point.
"""
struct MultiPointZ <: AbstractMultiPoint{PointZ}
    MBR::Rect
    points::Vector{Point}
    zrange::Interval
    zvalues::Vector{Float64}
    mrange::Interval
    measures::Vector{Float64}
end

Base.:(==)(p1::MultiPointZ, p2::MultiPointZ) =
    (p1.points == p2.points) && (p1.zvalues == p2.zvalues) && (p1.measures == p2.measures)

GI.getgeom(::GI.MultiPointTrait, geom::MultiPointZ, i::Integer) =
    PointZ(geom.points[i], geom.zvalues[i], geom.measures[i])

function Base.read(io::IO, ::Type{MultiPointZ})
    box = read(io, Rect)
    numpoints = read(io, Int32)
    points = _readpoints(io, numpoints)
    zrange, zvalues = _readz(io, numpoints)
    mrange, measures = _readm(io, numpoints)
    MultiPointZ(box, points, zrange, zvalues, mrange, measures)
end
