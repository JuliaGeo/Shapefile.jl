@recipe function f(t::Table)
    getshp(t)
end

@recipe function f(shp::Handle)
    shp.shapes
end
