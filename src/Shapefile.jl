module Shapefile

using GeometryBasics: GeometryBasics
using GeometryBasics.StructArrays

import DBFTables, Tables

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

const linestrings = GB.LineString{2,Float64,GB.Point{2,Float64}}[GB.LineString([GB.Point(0.0, 1.0)])]

const Point = GB.Point{2, Float64}
const PointM = typeof(GB.meta(Point(0), m=1.0))
const PointZ = typeof(GB.meta(Point(0), z=1.0, m=1.0))

const MultiPoint = typeof(GB.MultiPointMeta(
    [Point(0)],
    boundingbox=Rect(0.0, 0.0, 2.0, 2.0), 
))

const MultiPointM = typeof(GB.MultiPointMeta(
    [Point(0)], m=[1.0],
    boundingbox=Rect(0,0,2,2)
))

const MultiPointZ = typeof(GB.MultiPointMeta(
    [Point(0)], z=[1.0], m=[1.0],
    boundingbox=Rect(0,0,2,2)
))

_poly_ = GB.Polygon(
                GB.LineString([Point(0.0, 0.0),   Point(0.0,   100.0)]),
               [GB.LineString([Point(1.0, 1.0),   Point(0.0,   100.0)]),
                GB.LineString([Point(0.0, 100.0), Point(200.0, 100.0)])
            ])

_multi_poly_ = GB.MultiPolygon([_poly_])

#Construction from type aliases for Polygon is not supported yet
const Polygon = typeof(GB.MultiPolygonMeta(_multi_poly_,
                       boundingbox = Rect(0.0, 0.0, 2.0, 2.0)
 ))

const PolygonM = typeof(GB.MultiPolygonMeta(_multi_poly_,
                       m = [1.0], boundingbox = Rect(0.0, 0.0, 2.0, 2.0)
  ))

const PolygonZ = typeof(GB.MultiPolygonMeta(_multi_poly_,
                       z = [1.0], m = [1.0], boundingbox = Rect(0.0, 0.0, 2.0, 2.0)
  ))

const Polyline = typeof(GB.MultiLineStringMeta( 
    GB.MultiLineString(linestrings),
    boundingbox = Rect(0.0, 0.0, 2.0, 2.0)
))

const PolylineM = typeof(GB.MultiLineStringMeta(
    GB.MultiLineString(linestrings),
    m = [1.0], boundingbox = Rect(0.0, 0.0, 2.0, 2.0)
)) 

const PolylineZ = typeof(GB.MultiLineStringMeta(
    GB.MultiLineString(linestrings),
    z = [1.0], m = [1.0], boundingbox = Rect(0.0, 0.0, 2.0, 2.0)
)) 

# const MultiPatch = typeof(GB.MeshMeta(
#     [Point(0.0)], [1],
#     p = [1.0], z = [1.0], boundingbox = Rect(0.0, 0.0, 2.0, 2.0)
# )) 
 
struct MultiPatch
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
    m_linestrings = parts_polyline(points, parts)
    GB.MultiLineStringMeta(m_linestrings, boundingbox = box)
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
    m_linestrings = parts_polyline(points, parts)
    GB.MultiLineStringMeta(m_linestrings, m = measures, boundingbox = box)
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
    m_linestrings = parts_polyline(points, parts)
    GB.MultiLineStringMeta(m_linestrings, z = zvalues, m = measures, boundingbox = box)
end

function Base.read(io::IO, ::Type{Polygon}) 
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    multipolygon = parts_polygon(points, parts)
    GB.MultiPolygonMeta(multipolygon, boundingbox = box)
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
    multipolygon = parts_polygon(points, parts)
    GB.MultiPolygonMeta(multipolygon, m = measures, boundingbox = box)
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
    multipolygon = parts_polygon(points, parts)
    GB.MultiPolygonMeta(multipolygon, z = zvalues, m = measures, boundingbox = box)
end

function Base.read(io::IO, ::Type{MultiPoint}) 
    box = read(io, Rect)
    numpoints = read(io, Int32)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    multipoint = GB.MultiPoint(points)
    return GB.MultiPointMeta(multipoint, boundingbox=box)
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
    multipoint = GB.MultiPoint(points)
    return GB.MultiPointMeta(multipoint, m=measures, boundingbox=box)
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
    multipoint = GB.MultiPoint(points)
    return GB.MultiPointMeta(multipoint, z=zvalues, m=measures, boundingbox=box)
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
    
    # parts .+= 1
    # return GB.MeshMeta(points, parts, p = parttypes, z = zvalues, boundingbox = box)
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
    shapes = Vector{jltype}(undef, 0)
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
            push!(shapes, read(io, jltype))
            end
    end
    file
end

function Base.:(==)(a::Rect, b::Rect)
    a.left == b.left &&
    a.bottom == b.bottom && a.right == b.right && a.top == b.top
end

include("basics.jl")
include("table.jl")
include("shx.jl")

end # module
