module Shapefile

import GeoInterface
using DBFTables, DataFrames

mutable struct Rect
    left::Float64
    bottom::Float64
    right::Float64
    top::Float64
end

mutable struct Interval
    left::Float64
    right::Float64
end

mutable struct Point <: GeoInterface.AbstractPoint
    x::Float64
    y::Float64
end

mutable struct PointM <: GeoInterface.AbstractPoint
    x::Float64
    y::Float64
    m::Float64  # measure
end

mutable struct PointZ <: GeoInterface.AbstractPoint
    x::Float64
    y::Float64
    z::Float64
    m::Float64  # measure
end

mutable struct Polyline <: GeoInterface.AbstractMultiLineString
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
end

mutable struct PolylineM <: GeoInterface.AbstractMultiLineString
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    measures::Vector{Float64}
end

mutable struct PolylineZ <: GeoInterface.AbstractMultiLineString
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    zvalues::Vector{Float64}
    measures::Vector{Float64}
end

mutable struct Polygon <: GeoInterface.AbstractMultiPolygon
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
end

Base.show(io::IO,p::Polygon) = print(io,"Polygon(",length(p.points)," ",T," Points)")

mutable struct PolygonM <: GeoInterface.AbstractMultiPolygon
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    measures::Vector{Float64}
end

mutable struct PolygonZ <: GeoInterface.AbstractMultiPolygon
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    zvalues::Vector{Float64}
    measures::Vector{Float64}
end

mutable struct MultiPoint <: GeoInterface.AbstractMultiPoint
    MBR::Rect
    points::Vector{Point}
end

mutable struct MultiPointM <: GeoInterface.AbstractMultiPoint
    MBR::Rect
    points::Vector{Point}
    measures::Vector{Float64}
end

mutable struct MultiPointZ <: GeoInterface.AbstractMultiPoint
    MBR::Rect
    points::Vector{Point}
    zvalues::Vector{Float64}
    measures::Vector{Float64}
end

mutable struct MultiPatch <: GeoInterface.AbstractGeometry
    MBR::Rect
    parts::Vector{Int32}
    parttypes::Vector{Int32}
    points::Vector{Point}
    zvalues::Vector{Float64}
    # measures::Vector{Float64}  # (optional)
end

const SHAPETYPE = Dict{Int32, DataType}(
    0  => Missing,
    1  => Point,
    3  => Polyline,
    5  => Polygon,
    8  => MultiPoint,
    11 => PointZ,
    13 => PolylineZ,
    15 => PolygonZ,
    18 => MultiPointZ,
    21 => PointM,
    23 => PolylineM,
    25 => PolygonM,
    28 => MultiPointM,
    31 => MultiPatch
)

mutable struct Handle{T <: Union{<:GeoInterface.AbstractGeometry, Missing}}
    code::Int32
    length::Int32
    version::Int32
    shapeType::Int32
    MBR::Rect
    zrange::Interval{Float64}
    mrange::Interval{Float64}
    shapes::Vector{T}
end

function Base.read(io::IO,::Type{Rect})
    minx = read(io,T)
    miny = read(io,T)
    maxx = read(io,T)
    maxy = read(io,T)
    Rect(minx,miny,maxx,maxy)
end

function Base.read(io::IO,::Type{Point})
    x = read(io,T)
    y = read(io,T)
    Point(x,y)
end

function Base.read(io::IO,::Type{PointM})
    x = read(io,T)
    y = read(io,T)
    m = read(io,M)
    PointM(x,y,m)
end

function Base.read(io::IO,::Type{PointZ})
    x = read(io,T)
    y = read(io,T)
    z = read(io,T)
    m = read(io,M)
    PointZ(x,y,z,m)
end

function Base.read(io::IO,::Type{Polyline})
    box = read(io,Rect)
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    Polyline(box,parts,points)
end

function Base.read(io::IO,::Type{PolylineM})
    box = read(io,Rect)
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    mrange = Vector{M}(undef, 2)
    read!(io, mrange)
    measures = Vector{M}(undef, numpoints)
    read!(io, measures)
    PolylineM(box,parts,points,measures)
end

function Base.read(io::IO,::Type{PolylineZ})
    box = read(io,Rect)
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    zrange = Vector{T}(undef, 2)
    read!(io, zrange)
    zvalues = Vector{T}(undef, numpoints)
    read!(io, zvalues)
    mrange = Vector{M}(undef, 2)
    read!(io, mrange)
    measures = Vector{M}(undef, numpoints)
    read!(io, measures)
    PolylineZ(box,parts,points,zvalues,measures)
end

function Base.read(io::IO,::Type{Polygon})
    box = read(io,Rect)
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    Polygon(box,parts,points)
end

function Base.read(io::IO,::Type{PolygonM})
    box = read(io,Rect)
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    mrange = Vector{M}(undef, 2)
    read!(io, mrange)
    measures = Vector{M}(undef, numpoints)
    read!(io, measures)
    PolygonM(box,parts,points,measures)
end

function Base.read(io::IO,::Type{PolygonZ})
    box = read(io,Rect)
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    zrange = Vector{Float64}(undef, 2)
    read!(io, zrange)
    zvalues = Vector{Float64}(undef, numpoints)
    read!(io, zvalues)
    mrange = Vector{Float64}(undef, 2)
    read!(io, mrange)
    measures = Vector{Flaot64}(undef, numpoints)
    read!(io, measures)
    PolygonZ(box,parts,points,zvalues,measures)
end

function Base.read(io::IO,::Type{MultiPoint})
    box = read(io,Rect)
    numpoints = read(io,Int32)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    MultiPoint(box,points)
end

function Base.read(io::IO,::Type{MultiPointM})
    box = read(io,Rect)
    numpoints = read(io,Int32)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    mrange = Vector{Float64}(undef, 2)
    read!(io, mrange)
    measures = Vector{Float64}(undef, numpoints)
    read!(io, measures)
    MultiPointM(box,points,measures)
end

function Base.read(io::IO,::Type{MultiPointZ})
    box = read(io,Rect)
    numpoints = read(io,Int32)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    zrange = Vector{Float64}(undef, 2)
    read!(io, zrange)
    zvalues = Vector{Float64}(undef, numpoints)
    read!(io, zvalues)
    mrange = Vector{Float64}(undef, 2)
    read!(io, mrange)
    measures = Vector{Float64}(undef, numpoints)
    read!(io, measures)
    MultiPointZ(box,points,zvalues,measures)
end

function Base.read(io::IO,::Type{MultiPatch{T,M}}) where {T,M}
    box = read(io,Rect)
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    parttypes = Vector{Int32}(undef, numparts)
    read!(io, parttypes)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    zrange = Vector{Float64}(undef, 2)
    read!(io, zrange)
    zvalues = Vector{Float64}(undef, numpoints)
    read!(io, zvalues)
    # mrange = Vector{M}(2)
    # read!(io, mrange)
    # measures = Vector{M}(numpoints)
    # read!(io, measures)
    MultiPatch{T,M}(box,parts,parttypes,points,zvalues) #,measures)
end

function Base.read(io::IO,::Type{Handle})
    code = bswap(read(io,Int32))
    read!(io, Vector{Int32}(undef, 5))
    fileSize = bswap(read(io,Int32))
    version = read(io,Int32)
    shapeType = read(io,Int32)
    MBR = read(io,Rect)
    zmin = read(io,Float64)
    zmax = read(io,Float64)
    mmin = read(io,Float64)
    mmax = read(io,Float64)
    jltype = SHAPETYPE[shapeType]
    shapes = Vector{Union{jltype, Missing}}(undef, 0)
    file = Handle(code,fileSize,version,shapeType,MBR,Interval(zmin,zmax),Interval(mmin,mmax),shapes)
    while(!eof(io))
        num = bswap(read(io,Int32))
        rlength = bswap(read(io,Int32))
        shapeType = read(io,Int32)
        if shapeType === Int32(0)
            push!(shapes, missing)
        else
            push!(shapes, read(io, jltype))
        end
    end
    file
end

function Base.:(==)(a::Rect, b::Rect)
    a.left == b.left &&
        a.bottom == b.bottom &&
        a.right == b.right &&
        a.top == b.top
end

include("geo_interface.jl")
include("shx.jl")
include("parsefile.jl")

end # module
