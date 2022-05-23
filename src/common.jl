
abstract type AbstractShape end

GeoInterface.isgeometry(::Type{<:AbstractShape}) = true
GeoInterface.ncoord(::GI.AbstractGeometryTrait, ::AbstractShape) = 2 # With specific methods when 3

Base.convert(T::Type{<:AbstractShape}, geom) = Base.convert(T, GI.geomtrait(geom), geom)
Base.convert(::Type{T}, geom::T) where {T<:AbstractShape} = geom
Base.convert(::Type{<:AbstractShape}, ::Nothing, geom) =
    throw(ArgumentError("object to convert is not a GeoInterface compatible geometry"))

"""
    Rect

A rectangle object to represent the bounding box for other shape file shapes.
"""
struct Rect
    left::Float64
    bottom::Float64
    right::Float64
    top::Float64
end

function Base.read(io::IO, ::Type{Rect})
    minx = read(io, Float64)
    miny = read(io, Float64)
    maxx = read(io, Float64)
    maxy = read(io, Float64)
    Rect(minx, miny, maxx, maxy)
end

function Base.:(==)(a::Rect, b::Rect)
    a.left == b.left &&
    a.bottom == b.bottom && a.right == b.right && a.top == b.top
end

"""
    Interval

Represents the range of measures or Z dimension, in a shape file.
"""
struct Interval
    left::Float64
    right::Float64
end

function Base.read(io::IO, ::Type{Interval})
    left = read(io, Float64)
    right = read(io, Float64)
    Interval(left, right)
end
