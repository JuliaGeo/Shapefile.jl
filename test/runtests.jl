using Shapefile, GeoInterface
using Test

test_tuples = [
    (
        path="shapelib_testcases/test.shp",
        geomtype=Shapefile.Polygon{Float64},
        coordinates=Array{Array{Array{Array{Float64,1},1},1},1}[Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[20.0,20.0],[20.0,30.0],[30.0,30.0],[20.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[100.0,0.0],[100.0,100.0],[0.0,100.0],[0.0,0.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[150.0,150.0],[160.0,150.0],[180.0,170.0],[150.0,150.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[150.0,150.0],[160.0,150.0],[180.0,170.0],[150.0,150.0]]]]],
        bbox=Shapefile.Rect{Float64}(0.0, 0.0, 180.0, 170.0),
        ),(
        path="shapelib_testcases/test0.shp",
        geomtype=Missing,
        coordinates=nothing,
        bbox=Shapefile.Rect{Float64}(0.0, 0.0, 10.0, 20.0),
    ),(
        path="shapelib_testcases/test1.shp",
        geomtype=Shapefile.Point{Float64},
        coordinates=Array{Float64,1}[[1.0,2.0],[10.0,20.0]],
        bbox=Shapefile.Rect{Float64}(1.0, 2.0, 10.0, 20.0),
    ),(
        path="shapelib_testcases/test2.shp",
        geomtype=Shapefile.PointZ{Float64,Float64},
        coordinates=Array{Float64,1}[[1.0,2.0,3.0],[10.0,20.0,30.0]],
        bbox=Shapefile.Rect{Float64}(1.0, 2.0, 10.0, 20.0),
    ),(
        path="shapelib_testcases/test3.shp",
        geomtype=Shapefile.PointM{Float64,Float64},
        coordinates=Array{Float64,1}[[1.0,2.0],[10.0,20.0]],
        bbox=Shapefile.Rect{Float64}(1.0, 2.0, 10.0, 20.0),
    ),(
        path="shapelib_testcases/test4.shp",
        geomtype=Shapefile.MultiPoint{Float64},
        coordinates=Array{Array{Float64,1},1}[Array{Float64,1}[[1.15,2.25],[2.15,3.25],[3.15,4.25],[4.15,5.25]],Array{Float64,1}[[11.15,12.25],[12.15,13.25],[13.15,14.25],[14.15,15.25]],Array{Float64,1}[[21.15,22.25],[22.15,23.25],[23.15,24.25],[24.15,25.25]]],
        bbox=Shapefile.Rect{Float64}(1.15, 2.25, 24.15, 25.25),
    ),(
        path="shapelib_testcases/test5.shp",
        geomtype=Shapefile.MultiPointZ{Float64,Float64},
        coordinates=Array{Array{Float64,1},1}[Array{Float64,1}[[1.15,2.25],[2.15,3.25],[3.15,4.25],[4.15,5.25]],Array{Float64,1}[[11.15,12.25],[12.15,13.25],[13.15,14.25],[14.15,15.25]],Array{Float64,1}[[21.15,22.25],[22.15,23.25],[23.15,24.25],[24.15,25.25]]],
        bbox=Shapefile.Rect{Float64}(1.15, 2.25, 24.15, 25.25),
    ),(
        path="shapelib_testcases/test6.shp",
        geomtype=Shapefile.MultiPointM{Float64,Float64},
        coordinates=Array{Array{Float64,1},1}[Array{Float64,1}[[1.15,2.25],[2.15,3.25],[3.15,4.25],[4.15,5.25]],Array{Float64,1}[[11.15,12.25],[12.15,13.25],[13.15,14.25],[14.15,15.25]],Array{Float64,1}[[21.15,22.25],[22.15,23.25],[23.15,24.25],[24.15,25.25]]],
        bbox=Shapefile.Rect{Float64}(1.15, 2.25, 24.15, 25.25),
    ),(
        path="shapelib_testcases/test7.shp",
        geomtype=Shapefile.Polyline{Float64},
        coordinates=Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]],
        bbox=Shapefile.Rect{Float64}(0.0, 0.0, 100.0, 100.0),
    ),(
        path="shapelib_testcases/test8.shp",
        geomtype=Shapefile.PolylineZ{Float64,Float64},
        coordinates=Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]],
        bbox=Shapefile.Rect{Float64}(0.0, 0.0, 100.0, 100.0),
    ),(
        path="shapelib_testcases/test9.shp",
        geomtype=Shapefile.PolylineM{Float64,Float64},
        coordinates=Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]],
        bbox=Shapefile.Rect{Float64}(0.0, 0.0, 100.0, 100.0),
    ),(
        path="shapelib_testcases/test10.shp",
        geomtype=Shapefile.Polygon{Float64},
        coordinates=Array{Array{Array{Array{Float64,1},1},1},1}[Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]]],
        bbox=Shapefile.Rect{Float64}(0.0, 0.0, 100.0, 100.0),
    ),(
        path="shapelib_testcases/test11.shp",
        geomtype=Shapefile.PolygonZ{Float64,Float64},
        coordinates=Array{Array{Array{Array{Float64,1},1},1},1}[Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]]],
        bbox=Shapefile.Rect{Float64}(0.0, 0.0, 100.0, 100.0),
    ),(
        path="shapelib_testcases/test12.shp",
        geomtype=Shapefile.PolygonM{Float64,Float64},
        coordinates=Array{Array{Array{Array{Float64,1},1},1},1}[Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]]],Array{Array{Array{Float64,1},1},1}[Array{Array{Float64,1},1}[Array{Float64,1}[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]]],Array{Array{Float64,1},1}[Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]]],
        bbox=Shapefile.Rect{Float64}(0.0, 0.0, 100.0, 100.0),
    ),(
        path="shapelib_testcases/test13.shp",
        geomtype=Shapefile.MultiPatch{Float64,Float64},
        coordinates=nothing,
        bbox=Shapefile.Rect{Float64}(0.0, 0.0, 100.0, 100.0),
    )
]

@testset "Shapefile" begin

for test in test_tuples
    shp = open(joinpath(@__DIR__, test.path)) do fd
        read(fd, Shapefile.Handle)
    end
    shapes = unique(map(typeof, shp.shapes))
    @test length(shapes) == 1
    @test shapes[1] == test.geomtype
    @test eltype(shp.shapes) == Union{test.geomtype, Missing}
    # missing and MultiPatch are not covered by the GeoInterface
    if !(test.geomtype <: Union{Missing, Shapefile.MultiPatch})
        @test GeoInterface.coordinates.(shp.shapes) == test.coordinates
    end
    @test shp.MBR == test.bbox
end

# Test all .shx files; the values in .shx must match the .shp offsets
for test in test_tuples

    offsets = Int32[]
    contentlens = Int32[]

    # Get the shapefile's record offsets and contentlens
    shp = open(joinpath(@__DIR__, test.path)) do fd
        seek(fd,32)
        shapeType = read(fd,Int32)
        seek(fd,100)
        jltype = Shapefile.SHAPETYPE[shapeType]

        push!(offsets, position(fd))
        while(!eof(fd))

            num = bswap(read(fd,Int32))
            rlength = bswap(read(fd,Int32))
            shapeType = read(fd,Int32)
            if shapeType !== Int32(0)
                read(fd, jltype)
            end

            # records the offest after this geometry record
            push!(offsets, position(fd))
        end
    end
    contentlens = diff(offsets)
    offsets = offsets[1:end-1]

    # Match the Index values to Shapefile offsets
    shx = open(joinpath(@__DIR__, replace(test.path, r".shp$"=>".shx"))) do fd
        shx = read(fd, Shapefile.IndexHandle)
        for sIdx = 1:lastindex(shx.indices)
            @test shx.indices[sIdx].offset*2       == offsets[sIdx]
            @test shx.indices[sIdx].contentLen*2+8 == contentlens[sIdx]
        end
    end

end

end  # @testset "Shapefile"
