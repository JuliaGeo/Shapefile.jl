module Shapefile

using GeometryBasics: GeometryBasics
using GeometryBasics.StructArrays

import GeoInterface, DBFTables, Tables

const GB = GeometryBasics

struct Rect
    left::Float64
    bottom::Float64
    right::Float64
    top::Float64
end

struct Interval
    left::Float64
    right::Float64
end

const Point = GB.Point{2, Float64}
const PointM = typeof(GB.meta(Point(0), m=1.0))
const PointZ = typeof(GB.meta(Point(0), z=1.0, m=1.0))

const MultiPoint = typeof(GB.MultiPointMeta(
    [Point(0)],
    boundingbox=Rect(0,0,2,2)
))

const MultiPointM = typeof(GB.MultiPointMeta(
    GB.MultiPoint([Point(0)], m=[1.0]),
    boundingbox=Rect(0,0,2,2)
))

const MultiPointZ = typeof(GB.MultiPointMeta(
    GB.MultiPoint([Point(0)], z=[1.0], m=[1.0]),
    boundingbox=Rect(0,0,2,2)
))

const Polygon =  typeof(GB.PolygonMeta(
    [Point(0.0, 1.0)], [0],
    boundingbox = Rect(0.0, 0.0, 2.0, 2.0)
))

# GB.MultiLineString([GB.LineString([Point(0)])])

struct Polyline <: GeoInterface.AbstractMultiLineString
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
end

struct PolylineM <: GeoInterface.AbstractMultiLineString
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    measures::Vector{Float64}
end

struct PolylineZ <: GeoInterface.AbstractMultiLineString
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    zvalues::Vector{Float64}
    measures::Vector{Float64}
end
# Do we keep Base.show?
# Base.show(io::IO, p::Polygon) =
#     print(io, "Polygon(", length(p.points), " Points)")

struct PolygonM <: GeoInterface.AbstractMultiPolygon
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    measures::Vector{Float64}
end

struct PolygonZ <: GeoInterface.AbstractMultiPolygon
    MBR::Rect
    parts::Vector{Int32}
    points::Vector{Point}
    zvalues::Vector{Float64}
    measures::Vector{Float64}
end

struct MultiPatch <: GeoInterface.AbstractGeometry
    MBR::Rect
    parts::Vector{Int32}
    parttypes::Vector{Int32}
    points::Vector{Point}
    zvalues::Vector{Float64}
    # measures::Vector{Float64}  # (optional)
end

const SHAPETYPE = Dict{Int32,DataType}(
    0 => Missing,
    1 => Point,
    3 => Polyline,
    5 => Polygon,
    8 => MultiPoint,
    11 => PointZ,
    13 => PolylineZ,
    15 => PolygonZ,
    18 => MultiPointZ,
    21 => PointM,
    23 => PolylineM,
    25 => PolygonM,
    28 => MultiPointM,
    31 => MultiPatch,
)

mutable struct Handle{T}
    code::Int32
    length::Int32
    version::Int32
    shapeType::Int32
    MBR::Rect
    zrange::Interval
    mrange::Interval
    shapes::Vector{T}
end

Base.length(shp::Handle) = length(shp.shapes)

function Base.read(io::IO, ::Type{Rect})
    minx = read(io, Float64)
    miny = read(io, Float64)
    maxx = read(io, Float64)
    maxy = read(io, Float64)
    Rect(minx, miny, maxx, maxy)
end

function Base.read(io::IO, ::Type{Point})
    x = read(io, Float64)
    y = read(io, Float64)
    Point(x, y)
end

function Base.read(io::IO, ::Type{PointM})
    x = read(io, Float64)
    y = read(io, Float64)
    m = read(io, Float64)
    GB.meta(Point(x, y), m=m)
end

function Base.read(io::IO, ::Type{PointZ})
    x = read(io, Float64)
    y = read(io, Float64)
    z = read(io, Float64)
    m = read(io, Float64)
    GB.meta(Point(x, y), z=z, m=m)
end

function Base.read(io::IO, ::Type{Polyline})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    Polyline(box, parts, points)
end

function Base.read(io::IO, ::Type{PolylineM})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    mrange = Vector{Float64}(undef, 2)
    read!(io, mrange)
    measures = Vector{Float64}(undef, numpoints)
    read!(io, measures)
    PolylineM(box, parts, points, measures)
end

function Base.read(io::IO, ::Type{PolylineZ})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
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
    measures = Vector{Float64}(undef, numpoints)
    read!(io, measures)
    PolylineZ(box, parts, points, zvalues, measures)
end

function Base.read(io::IO, ::Type{Polygon})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    return GB.meta(GB.Polygon(points, parts), boundingbox = box)
end

function Base.read(io::IO, ::Type{PolygonM})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    mrange = Vector{Float64}(undef, 2)
    read!(io, mrange)
    measures = Vector{Float64}(undef, numpoints)
    read!(io, measures)
    PolygonM(box, parts, points, measures)
end

function Base.read(io::IO, ::Type{PolygonZ})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
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
    measures = Vector{Float64}(undef, numpoints)
    read!(io, measures)
    PolygonZ(box, parts, points, zvalues, measures)
end

function Base.read(io::IO, ::Type{MultiPoint})
    box = read(io, Rect)
    numpoints = read(io, Int32)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    return GB.meta(points, boundingbox=box)
end

function Base.read(io::IO, ::Type{MultiPointM})
    box = read(io, Rect)
    numpoints = read(io, Int32)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    mrange = Vector{Float64}(undef, 2)
    read!(io, mrange)
    measures = Vector{Float64}(undef, numpoints)
    read!(io, measures)
    multipoints = MultiPoint(points, m=measures)
    return GB.meta(multipoints, boundingbox=box)
end

function Base.read(io::IO, ::Type{MultiPointZ})
    box = read(io, Rect)
    numpoints = read(io, Int32)
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
    multipoints = MultiPoint(points, z=zvalues, m=measures)
    return GB.meta(multipoints, boundingbox=box)
end

function Base.read(io::IO, ::Type{MultiPatch})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
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
    # mrange = Vector{Float64}(2)
    # read!(io, mrange)
    # measures = Vector{Float64}(numpoints)
    # read!(io, measures)
    MultiPatch(box, parts, parttypes, points, zvalues) #,measures)
end

function Base.read(io::IO, ::Type{Handle})
    code = bswap(read(io, Int32))
    read!(io, Vector{Int32}(undef, 5))
    fileSize = bswap(read(io, Int32))
    version = read(io, Int32)
    shapeType = read(io, Int32)
    MBR = read(io, Rect)
    zmin = read(io, Float64)
    zmax = read(io, Float64)
    mmin = read(io, Float64)
    mmax = read(io, Float64)
    jltype = SHAPETYPE[shapeType]
    shapes = Vector{Any}(undef, 0) #TODO figure out a type
    file = Handle(
        code,
        fileSize,
        version,
        shapeType,
        MBR,
        Interval(zmin, zmax),
        Interval(mmin, mmax),
        shapes,
    )
    while (!eof(io))
        num = bswap(read(io, Int32))
        rlength = bswap(read(io, Int32))
        shapeType = read(io, Int32)
        if shapeType === Int32(0)
            push!(shapes, missing)
        else
            push!(shapes, GB.metafree(read(io, jltype)))
        end
    end
    file
end

function Base.:(==)(a::Rect, b::Rect)
    a.left == b.left &&
    a.bottom == b.bottom && a.right == b.right && a.top == b.top
end

include("table.jl")
include("geo_interface.jl")
include("shx.jl")

end # module
 