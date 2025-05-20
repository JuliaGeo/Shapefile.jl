module Shapefile

import GeoFormatTypes, GeoInterface, DBFTables, Extents, Tables, DataAPI
const GI = GeoInterface
const GFT = GeoFormatTypes

include("common.jl")
include("points.jl")
include("polygons.jl")
include("polylines.jl")
include("multipoints.jl")
include("multipatch.jl")
include("utils.jl")

# Handle/Table

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

const SHAPECODE = Dict((v => k for (k, v) in SHAPETYPE))

const TRAITSHAPE = Dict{DataType,DataType}(
    Nothing => Missing,
    Missing => Missing,
    GI.PointTrait => Point,
    GI.LineStringTrait => Polyline,
    GI.MultiLineStringTrait => Polyline,
    GI.PolygonTrait => Polygon,
    GI.MultiPolygonTrait => Polygon,
    GI.MultiPointTrait => MultiPoint,
)
const TRAITSHAPE_Z = Dict{DataType,DataType}(
    Nothing => Missing,
    Missing => Missing,
    GI.PointTrait => PointZ,
    GI.MultiLineStringTrait => PolylineZ,
    GI.MultiPolygonTrait => PolygonZ,
    GI.MultiPointTrait => MultiPointZ,
)

const TRAITSHAPE_M = Dict{DataType,DataType}(
    Nothing => Missing,
    Missing => Missing,
    GI.PointTrait => PointM,
    GI.MultiLineStringTrait => PolylineM,
    GI.MultiPolygonTrait => PolygonM,
    GI.MultiPointTrait => MultiPointM,
)

include("shx.jl")
include("handle.jl")
include("table.jl")
include("extent.jl")
include("writer.jl")

function __init__()
    # Register an error hint, so that if a user tries to read a zipfile and fails, they get a helpful error message
    # that includes the ShapefileZipFileExt package.
    Base.Experimental.register_error_hint(MethodError) do io, exc, argtypes, kwargs
        if exc.f == _read_shp_from_zipfile
            if isnothing(Base.get_extension(Shapefile, :ShapefileZipFileExt))
                print(io, "\nPlease load the ")
                printstyled(io, "ZipFile", color=:cyan)
                println(io, " package to read zipfiles into Shapefile.Table objects.")
                println(io, "You can do this by typing: ")
                printstyled(io, "using ZipFile", color=:cyan, bold = true)
                println(io, "\ninto your REPL or code.")
            end
        end
    end
end

end # module
