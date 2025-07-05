module ShapefileRecipesBaseExt

import GeoInterface
import RecipesBase
import Shapefile

RecipesBase.@recipe function f(t::Shapefile.Table)
    Shapefile.getshp(t)
end

RecipesBase.@recipe function f(shp::Shapefile.Handle)
    Shapefile.shapes(shp)
end

GeoInterface.@enable_plots RecipesBase Shapefile.AbstractShape
GeoInterface.@enable_plots RecipesBase Shapefile.SubPolygon
GeoInterface.@enable_plots RecipesBase Shapefile.LinearRing

end
