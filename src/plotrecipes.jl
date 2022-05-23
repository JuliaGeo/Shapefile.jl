@recipe function f(t::Table)
    getshp(t)
end

@recipe function f(shp::Handle)
    shapes(shp)
end

GeoInterfaceRecipes.@enable_geo_plots Shapefile.AbstractShape
