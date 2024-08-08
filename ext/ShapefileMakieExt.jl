module ShapefileMakieExt
using GeoInterfaceMakie: GeoInterfaceMakie
using Shapefile: Shapefile
using Makie: Makie

GeoInterfaceMakie.@enable Shapefile.AbstractShape
GeoInterfaceMakie.@enable Shapefile.SubPolygon
GeoInterfaceMakie.@enable Shapefile.LinearRing

Makie.plottype(tbl::Shapefile.Table) = Makie.plottype(Shapefile.shapes(tbl))
Makie.plottype(shp::Shapefile.Handle) = Makie.plottype(Shapefile.shapes(shp))

for T in (Makie.ConversionTrait, Type{<:Makie.AbstractPlot}, Type{<:Makie.Poly}, Type{<:Makie.Lines}, Makie.PointBased)
    @eval begin
        Makie.convert_arguments(t::$T, tbl::Shapefile.Table) =
            Makie.convert_arguments(t, Shapefile.shapes(tbl))
        Makie.convert_arguments(t::$T, shp::Shapefile.Handle) =
            Makie.convert_arguments(t, Shapefile.shapes(shp))
    end
end

end
