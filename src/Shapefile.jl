module Shapefile

import GeoInterface

mutable struct Rect{T}
    left::T
    bottom::T
    right::T
    top::T
end

mutable struct Interval{T}
    left::T
    right::T
end

mutable struct Point{T} <: GeoInterface.AbstractPoint
    x::T
    y::T
end

mutable struct PointM{T,M} <: GeoInterface.AbstractPoint
    x::T
    y::T
    m::M # measure
end

mutable struct PointZ{T,M} <: GeoInterface.AbstractPoint
    x::T
    y::T
    z::T
    m::M # measure
end

mutable struct Polyline{T} <: GeoInterface.AbstractMultiLineString
    MBR::Rect{T}
    parts::Vector{Int32}
    points::Vector{Point{T}}
end

mutable struct PolylineM{T,M} <: GeoInterface.AbstractMultiLineString
    MBR::Rect{T}
    parts::Vector{Int32}
    points::Vector{Point{T}}
    measures::Vector{M}
end

mutable struct PolylineZ{T,M} <: GeoInterface.AbstractMultiLineString
    MBR::Rect{T}
    parts::Vector{Int32}
    points::Vector{Point{T}}
    zvalues::Vector{T}
    measures::Vector{M}
end

mutable struct Polygon{T} <: GeoInterface.AbstractMultiPolygon
    MBR::Rect{T}
    parts::Vector{Int32}
    points::Vector{Point{T}}
end

Base.show(io::IO,p::Polygon{T}) where {T} = print(io,"Polygon(",length(p.points)," ",T," Points)")

mutable struct PolygonM{T,M} <: GeoInterface.AbstractMultiPolygon
    MBR::Rect{T}
    parts::Vector{Int32}
    points::Vector{Point{T}}
    measures::Vector{M}
end

mutable struct PolygonZ{T,M} <: GeoInterface.AbstractMultiPolygon
    MBR::Rect{T}
    parts::Vector{Int32}
    points::Vector{Point{T}}
    zvalues::Vector{T}
    measures::Vector{M}
end

mutable struct MultiPoint{T} <: GeoInterface.AbstractMultiPoint
    MBR::Rect{T}
    points::Vector{Point{T}}
end

mutable struct MultiPointM{T,M} <: GeoInterface.AbstractMultiPoint
    MBR::Rect{T}
    points::Vector{Point{T}}
    measures::Vector{M}
end

mutable struct MultiPointZ{T,M} <: GeoInterface.AbstractMultiPoint
    MBR::Rect{T}
    points::Vector{Point{T}}
    zvalues::Vector{T}
    measures::Vector{M}
end

mutable struct MultiPatch{T,M} <: GeoInterface.AbstractGeometry
    MBR::Rect{T}
    parts::Vector{Int32}
    parttypes::Vector{Int32}
    points::Vector{Point{T}}
    zvalues::Vector{T}
    # measures::Vector{M} # (optional)
end

const SHAPETYPE = Dict{Int32, Any}(
    0  => Missing,
    1  => Point{Float64},
    3  => Polyline{Float64},
    5  => Polygon{Float64},
    8  => MultiPoint{Float64},
    11 => PointZ{Float64,Float64},
    13 => PolylineZ{Float64,Float64},
    15 => PolygonZ{Float64,Float64},
    18 => MultiPointZ{Float64,Float64},
    21 => PointM{Float64,Float64},
    23 => PolylineM{Float64,Float64},
    25 => PolygonM{Float64,Float64},
    28 => MultiPointM{Float64,Float64},
    31 => MultiPatch{Float64,Float64}
)

mutable struct Handle{T <: Union{<:GeoInterface.AbstractGeometry, Missing}}
    code::Int32
    length::Int32
    version::Int32
    shapeType::Int32
    MBR::Rect{Float64}
    zrange::Interval{Float64}
    mrange::Interval{Float64}
    shapes::Vector{T}
end

function Base.read(io::IO,::Type{Rect{T}}) where T
    minx = read(io,T)
    miny = read(io,T)
    maxx = read(io,T)
    maxy = read(io,T)
    Rect{T}(minx,miny,maxx,maxy)
end

function Base.read(io::IO,::Type{Point{T}}) where T
    x = read(io,T)
    y = read(io,T)
    Point{T}(x,y)
end

function Base.read(io::IO,::Type{PointM{T,M}}) where {T,M}
    x = read(io,T)
    y = read(io,T)
    m = read(io,M)
    PointM{T,M}(x,y,m)
end

function Base.read(io::IO,::Type{PointZ{T,M}}) where {T,M}
    x = read(io,T)
    y = read(io,T)
    z = read(io,T)
    m = read(io,M)
    PointZ{T,M}(x,y,z,m)
end

function Base.read(io::IO,::Type{Polyline{T}}) where T
    box = read(io,Rect{T})
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    Polyline{T}(box,parts,points)
end

function Base.read(io::IO,::Type{PolylineM{T,M}}) where {T,M}
    box = read(io,Rect{T})
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    mrange = Vector{M}(undef, 2)
    read!(io, mrange)
    measures = Vector{M}(undef, numpoints)
    read!(io, measures)
    PolylineM{T,M}(box,parts,points,measures)
end

function Base.read(io::IO,::Type{PolylineZ{T,M}}) where {T,M}
    box = read(io,Rect{T})
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    zrange = Vector{T}(undef, 2)
    read!(io, zrange)
    zvalues = Vector{T}(undef, numpoints)
    read!(io, zvalues)
    mrange = Vector{M}(undef, 2)
    read!(io, mrange)
    measures = Vector{M}(undef, numpoints)
    read!(io, measures)
    PolylineZ{T,M}(box,parts,points,zvalues,measures)
end

function Base.read(io::IO,::Type{Polygon{T}}) where T
    box = read(io,Rect{Float64})
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    Polygon{T}(box,parts,points)
end

function Base.read(io::IO,::Type{PolygonM{T,M}}) where {T,M}
    box = read(io,Rect{Float64})
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    mrange = Vector{M}(undef, 2)
    read!(io, mrange)
    measures = Vector{M}(undef, numpoints)
    read!(io, measures)
    PolygonM{T,M}(box,parts,points,measures)
end

function Base.read(io::IO,::Type{PolygonZ{T,M}}) where {T,M}
    box = read(io,Rect{Float64})
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    zrange = Vector{T}(undef, 2)
    read!(io, zrange)
    zvalues = Vector{T}(undef, numpoints)
    read!(io, zvalues)
    mrange = Vector{M}(undef, 2)
    read!(io, mrange)
    measures = Vector{M}(undef, numpoints)
    read!(io, measures)
    PolygonZ{T,M}(box,parts,points,zvalues,measures)
end

function Base.read(io::IO,::Type{MultiPoint{T}}) where T
    box = read(io,Rect{Float64})
    numpoints = read(io,Int32)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    MultiPoint{T}(box,points)
end

function Base.read(io::IO,::Type{MultiPointM{T,M}}) where {T,M}
    box = read(io,Rect{Float64})
    numpoints = read(io,Int32)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    mrange = Vector{M}(undef, 2)
    read!(io, mrange)
    measures = Vector{M}(undef, numpoints)
    read!(io, measures)
    MultiPointM{T,M}(box,points,measures)
end

function Base.read(io::IO,::Type{MultiPointZ{T,M}}) where {T,M}
    box = read(io,Rect{Float64})
    numpoints = read(io,Int32)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    zrange = Vector{T}(undef, 2)
    read!(io, zrange)
    zvalues = Vector{T}(undef, numpoints)
    read!(io, zvalues)
    mrange = Vector{M}(undef, 2)
    read!(io, mrange)
    measures = Vector{M}(undef, numpoints)
    read!(io, measures)
    MultiPointZ{T,M}(box,points,zvalues,measures)
end

function Base.read(io::IO,::Type{MultiPatch{T,M}}) where {T,M}
    box = read(io,Rect{Float64})
    numparts = read(io,Int32)
    numpoints = read(io,Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    parttypes = Vector{Int32}(undef, numparts)
    read!(io, parttypes)
    points = Vector{Point{T}}(undef, numpoints)
    read!(io, points)
    zrange = Vector{T}(undef, 2)
    read!(io, zrange)
    zvalues = Vector{T}(undef, numpoints)
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
    MBR = read(io,Rect{Float64})
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

end # module
