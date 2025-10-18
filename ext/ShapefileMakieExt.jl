module ShapefileMakieExt

import GeoInterface
import Shapefile
import Makie

GeoInterface.@enable_makie Makie Shapefile.AbstractShape
GeoInterface.@enable_makie Makie Shapefile.SubPolygon
GeoInterface.@enable_makie Makie Shapefile.LinearRing

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
