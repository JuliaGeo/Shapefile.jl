module Shapefile

import GeoFormatTypes, GeoInterface, GeoInterfaceRecipes, DBFTables, Extents, Tables

const GI = GeoInterface

using RecipesBase

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

include("shx.jl")
include("handle.jl")
include("table.jl")
include("extent.jl")
include("plotrecipes.jl")

end # module
