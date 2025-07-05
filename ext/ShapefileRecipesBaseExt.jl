module ShapefileRecipesBaseExt

import GeoJSON
import RecipesBase
import Shapefile

@recipe function f(t::Table)
    getshp(t)
end

@recipe function f(shp::Handle)
    shapes(shp)
end

GeoInterface.@enable_plots RecipesBase Shapefile.AbstractShape
GeoInterface.@enable_plots RecipesBase Shapefile.SubPolygon
GeoInterface.@enable_plots RecipesBase Shapefile.LinearRing

end
