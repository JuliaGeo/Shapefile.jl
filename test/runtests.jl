using Shapefile, GeoInterface
using Base.Test

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

coords = Dict{String, Any}(
    "test.shp" => Array{Array{Array{Array{Float64,1},1},1},1}[Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[20.0,20.0],[20.0,30.0],[30.0,30.0],[20.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[100.0,0.0],[100.0,100.0],[0.0,100.0],[0.0,0.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[150.0,150.0],[160.0,150.0],[180.0,170.0],[150.0,150.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[150.0,150.0],[160.0,150.0],[180.0,170.0],[150.0,150.0]]]]],
    "test1.shp" => Array{Float64,1}[[1.0,2.0],[10.0,20.0]],
    "test2.shp" => Array{Float64,1}[[1.0,2.0,3.0],[10.0,20.0,30.0]],
    "test3.shp" => Array{Float64,1}[[1.0,2.0],[10.0,20.0]],
    "test4.shp" => Array{Array{Float64,1},1}[Array{Float64,1}[[1.15,2.25],[2.15,3.25],[3.15,4.25],[4.15,5.25]],Array{Float64,1}[[11.15,12.25],[12.15,13.25],[13.15,14.25],[14.15,15.25]],Array{Float64,1}[[21.15,22.25],[22.15,23.25],[23.15,24.25],[24.15,25.25]]],
    "test5.shp" => Array{Array{Float64,1},1}[Array{Float64,1}[[1.15,2.25],[2.15,3.25],[3.15,4.25],[4.15,5.25]],Array{Float64,1}[[11.15,12.25],[12.15,13.25],[13.15,14.25],[14.15,15.25]],Array{Float64,1}[[21.15,22.25],[22.15,23.25],[23.15,24.25],[24.15,25.25]]],
    "test6.shp" => Array{Array{Float64,1},1}[Array{Float64,1}[[1.15,2.25],[2.15,3.25],[3.15,4.25],[4.15,5.25]],Array{Float64,1}[[11.15,12.25],[12.15,13.25],[13.15,14.25],[14.15,15.25]],Array{Float64,1}[[21.15,22.25],[22.15,23.25],[23.15,24.25],[24.15,25.25]]],
    "test7.shp" => Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]],
    "test8.shp" => Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]],
    "test9.shp" => Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]],
    "test10.shp" => Array{Array{Array{Array{Float64,1},1},1},1}[Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]]],
    "test11.shp" => Array{Array{Array{Array{Float64,1},1},1},1}[Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]]],
    "test12.shp" => Array{Array{Array{Array{Float64,1},1},1},1}[Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]]]
)

seen_types = Set(DataType[])
for test_file in readdir(joinpath(@__DIR__, "shapelib_testcases"))
    if splitext(test_file)[2] == ".shp"
        shp = open(joinpath(@__DIR__, "shapelib_testcases", test_file)) do fd
            read(fd,Shapefile.Handle)
        end
        shapes = unique(map(typeof,shp.shapes))
        @test length(shapes) == 1
        push!(seen_types, shapes[1])
        if test_file in keys(coords)
            @test map(GeoInterface.coordinates, shp.shapes) == coords[test_file]
        end
    end
end
@test seen_types == test_types
