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

const SHAPECODE = Dict((v => k for (k, v) in SHAPETYPE))

const TRAITSHAPE = Dict{Type,Type}(
    Nothing => Missing,
    Missing => Missing,
    GI.PointTrait => Point,
    GI.MultiLineStringTrait => Polyline,
    GI.MultiPolygonTrait => Polygon,
    GI.MultiPointTrait => MultiPoint,
)
const TRAITSHAPE_Z = Dict{Type,Type}(
    Nothing => Missing,
    Missing => Missing,
    GI.PointTrait => PointZ,
    GI.MultiLineStringTrait => PolylineZ,
    GI.MultiPolygonTrait => PolygonZ,
    GI.MultiPointTrait => MultiPointZ,
)

const TRAITSHAPE_M = Dict{Type,Type}(
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
include("plotrecipes.jl")
include("writer.jl")

end # module
