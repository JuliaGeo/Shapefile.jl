using Shapefile, FactCheck

test_types = Set([Shapefile.NullShape,
                  Shapefile.Point{Float64},
                  Shapefile.PointZ{Float64,Float64},
                  Shapefile.PointM{Float64,Float64},
                  Shapefile.MultiPoint{Float64},
                  Shapefile.MultiPointZ{Float64,Float64},
                  Shapefile.MultiPointM{Float64,Float64},
                  Shapefile.Polyline{Float64},
                  Shapefile.PolylineZ{Float64,Float64},
                  Shapefile.PolylineM{Float64,Float64},
                  Shapefile.Polygon{Float64},
                  Shapefile.PolygonZ{Float64,Float64},
                  Shapefile.PolygonM{Float64,Float64},
                  Shapefile.MultiPatch{Float64,Float64}])

seen_types = Set(DataType[])
for test_file in readdir(joinpath(dirname(@__FILE__), "shapelib_testcases"))
    if test_file[end-3:end] == ".shp"
        shp = open(joinpath(dirname(@__FILE__), "shapelib_testcases", test_file)) do fd
            read(fd,Shapefile.Handle)
        end
        shapes = unique(map(typeof,shp.shapes))
        @fact length(shapes) --> 1
        push!(seen_types, shapes[1])
    end
end
@fact seen_types --> test_types
