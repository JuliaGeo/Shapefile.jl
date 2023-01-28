
abstract type AbstractShape end

GeoInterface.isgeometry(::Type{<:AbstractShape}) = true
GeoInterface.ncoord(::GI.AbstractGeometryTrait, ::AbstractShape) = 2 # With specific methods when 3

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

union(r1::Rect, r2::Rect) =
    Rect(min(r1.left, r2.left), 
         min(r1.bottom, r2.bottom), 
         max(r1.right, r2.right),
         max(r1.top, r2.top)
    )

function Base.read(io::IO, ::Type{Rect})
    minx = read(io, Float64)
    miny = read(io, Float64)
    maxx = read(io, Float64)
    maxy = read(io, Float64)
    Rect(minx, miny, maxx, maxy)
end

function Base.write(io::IO, rect::Rect)
    bytes = Int32(0)
    bytes += Base.write(io, rect.left)
    bytes += Base.write(io, rect.bottom)
    bytes += Base.write(io, rect.right)
    bytes += Base.write(io, rect.top)
    return bytes
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

union(i1::Interval, i2::Interval) =
    Interval(min(i1.left, i2.left), max(i1.right, i2.right))

function Base.read(io::IO, ::Type{Interval})
    left = read(io, Float64)
    right = read(io, Float64)
    Interval(left, right)
end

function Base.write(io::IO, interval::Interval)
    Base.write(io, interval.left, interval.right)
end

"""
    Header

Common header read/write object for shp and shx files.
"""
struct Header
    code::Int32
    filesize::Int32
    version::Int32
    shapecode::Int32
    MBR::Rect
    zrange::Interval
    mrange::Interval
end
function Header(; filesize, shapecode, mbr, zrange, mrange)
    code = Int32(9994) # Shapefile file code is 9994
    version = Int32(1000) # Shapefile version is 1000
    return Header(code, filesize, version, shapecode, mbr, zrange, mrange)
end

function Base.read(io::IO, ::Type{Header})
    code = ntoh(read(io, Int32))
    read!(io, Vector{Int32}(undef,  5))
    filesize = ntoh(read(io, Int32))
    version = read(io, Int32)
    shapecode = read(io, Int32)
    mbr = read(io, Rect)
    zrange = read(io, Interval)
    mrange = read(io, Interval)
    return Header(code, filesize, version, shapecode, mbr, zrange, mrange)
end

function Base.write(io::IO, h::Header)
    bytes = 0
    bytes += Base.write(io, hton(h.code))
    bytes += Base.write(io, zeros(Int32,  5))
    bytes += Base.write(io, hton(h.filesize))
    bytes += Base.write(io, h.version)
    bytes += Base.write(io, h.shapecode)
    bytes += Base.write(io, h.MBR)
    bytes += Base.write(io, h.zrange)
    bytes += Base.write(io, h.mrange)
    return bytes
end
