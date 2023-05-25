
abstract type AbstractPoint <: AbstractShape end

GI.geomtrait(::AbstractPoint) = GI.PointTrait()
GI.x(::GI.PointTrait, point::AbstractPoint) = point.x
GI.y(::GI.PointTrait, point::AbstractPoint) = point.y
GI.getcoord(::GI.PointTrait, p::AbstractPoint, i::Integer) = getfield(p, i)
GI.ncoord(::GI.PointTrait, p::T) where {T<:AbstractPoint} = _ncoord(T)

_ncoord(::Type{<:AbstractPoint}) = 2

"""
    Point <: AbstractPoint

Point from a shape file.

Fields `x`, `y` hold the spatial location.
"""
struct Point <: AbstractPoint
    x::Float64
    y::Float64
end

function Base.read(io::IO, ::Type{Point})
    x = read(io, Float64)
    y = read(io, Float64)
    Point(x, y)
end

_ncoord(::Type{<:Point}) = 2

"""
    PointM <: AbstractPoint

Point from a shape file.

Fields `x`, `y` hold the spatial location.

Includes a measure field `m`, holding a value for the point.
"""
struct PointM <: AbstractPoint
    x::Float64
    y::Float64
    m::Float64  # measure
end
PointM(p::Point, m::Float64) = PointM(p.x, p.y, m)

function Base.read(io::IO, ::Type{PointM})
    x = read(io, Float64)
    y = read(io, Float64)
    m = read(io, Float64)
    PointM(x, y, m)
end

_ncoord(::Type{<:PointM}) = 3

GI.m(::GI.PointTrait, point::PointM) = point.m

"""
    PointZ <: AbstractPoint

Three dimensional point, from a shape file.

Fields `x`, `y`, `z` hold the spatial location.

Includes a measure field `m`, holding a value for the point.
"""
struct PointZ <: AbstractPoint
    x::Float64
    y::Float64
    z::Float64
    m::Float64  # measure
end
PointZ(p::Point, z, m) = PointZ(p.x, p.y, z, m)

function Base.read(io::IO, ::Type{PointZ})
    x = read(io, Float64)
    y = read(io, Float64)
    z = read(io, Float64)
    m = read(io, Float64)
    PointZ(x, y, z, m)
end

_ncoord(::Type{<:PointZ}) = 4

GI.m(::GI.PointTrait, point::PointZ) = point.m
GI.z(::GI.PointTrait, point::PointZ) = point.z
