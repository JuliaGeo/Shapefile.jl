using Shapefile, GeoInterface, Plots, Extents
using Shapefile
using GeoFormatTypes
using Test

const GI = GeoInterface


using Shapefile: Point, PointM, PointZ, Polygon, PolygonM, PolygonZ, Polyline,
    PolylineM, PolylineZ, MultiPoint, MultiPointM, MultiPointZ,
    MultiPatch, LineString, LinearRing, SubPolygon, Rect, Interval

shp = Shapefile.Handle(joinpath("shapelib_testcases", "test.shp"))

function cleanup()
    files = filter(readdir(@__DIR__)) do file
        any(ext -> endswith(file, ext), [".shp", ".shx", ".dbf", ".prj"])
    end
    rm.(files)
end

cleanup()

test_tuples = [
    (
        path=joinpath("shapelib_testcases", "test.shp"),
        geomtype=Polygon,
        coordinates=[[[[[20.0,20.0],[20.0,30.0],[30.0,30.0],[20.0,20.0]]],[[[0.0,0.0],[100.0,0.0],[100.0,100.0],[0.0,100.0],[0.0,0.0]]]],[[[[150.0,150.0],[160.0,150.0],[180.0,170.0],[150.0,150.0]]]],[[[[150.0,150.0],[160.0,150.0],[180.0,170.0],[150.0,150.0]]]]],
        extent=Extent(X=(0.0, 180.0), Y=(0.0, 170.0), Z=(0.0, 0.0)),
    ),(
        path=joinpath("shapelib_testcases", "test0.shp"),
        geomtype=Missing,
        coordinates=nothing,
        extent=Extent(X=(0.0, 10.0), Y=(0.0, 20.0), Z=(0.0, 0.0)),
        # This data has no shape, the correct bbox should be all zeros.
        # However the data contain some non-zero box values
        skip_check_mask = [43:44..., 51:52..., 59:60..., 67:68...],
    ),(
        path=joinpath("shapelib_testcases", "test1.shp"),
        geomtype=Point,
        coordinates=[[1.0,2.0],[10.0,20.0]],
        extent=Extent(X=(1.0, 10.0), Y=(2.0, 20.0), Z=(0.0, 0.0)),
    ),(
        path=joinpath("shapelib_testcases", "test2.shp"),
        geomtype=PointZ,
        coordinates=[[1.0,2.0,3.0],[10.0,20.0,30.0]],
        extent=Extent(X=(1.0, 10.0), Y=(2.0, 20.0), Z=(3.0, 30.0)),
    ),(
        path=joinpath("shapelib_testcases", "test3.shp"),
        geomtype=PointM,
        coordinates=[[1.0,2.0],[10.0,20.0]],
        extent=Extent(X=(1.0, 10.0), Y=(2.0, 20.0), Z=(0.0, 0.0)),
    ),(
        path=joinpath("shapelib_testcases", "test4.shp"),
        geomtype=MultiPoint,
        coordinates=[[[1.15,2.25],[2.15,3.25],[3.15,4.25],[4.15,5.25]],[[11.15,12.25],[12.15,13.25],[13.15,14.25],[14.15,15.25]],[[21.15,22.25],[22.15,23.25],[23.15,24.25],[24.15,25.25]]],
        extent=Extent(X=(1.15, 24.15), Y=(2.25, 25.25), Z=(0.0, 0.0)),
    ),(
        path=joinpath("shapelib_testcases", "test5.shp"),
        geomtype=MultiPointZ,
        coordinates=[[[1.15,2.25,3.35],[2.15,3.25,4.35],[3.15,4.25,5.35],[4.15,5.25,6.35]],[[11.15,12.25,13.35],[12.15,13.25,14.35],[13.15,14.25,15.35],[14.15,15.25,16.35]],[[21.15,22.25,23.35],[22.15,23.25,24.35],[23.15,24.25,25.35],[24.15,25.25,26.35]]],
        extent=Extent(X=(1.15, 24.15), Y=(2.25, 25.25), Z=(3.35, 26.35)),
    ),(
        path=joinpath("shapelib_testcases", "test6.shp"),
        geomtype=MultiPointM,
        coordinates=[[[1.15,2.25],[2.15,3.25],[3.15,4.25],[4.15,5.25]],[[11.15,12.25],[12.15,13.25],[13.15,14.25],[14.15,15.25]],[[21.15,22.25],[22.15,23.25],[23.15,24.25],[24.15,25.25]]],
        extent=Extent(X=(1.15, 24.15), Y=(2.25, 25.25), Z=(0.0, 0.0)),
    ),(
        path=joinpath("shapelib_testcases", "test7.shp"),
        geomtype=Polyline,
        coordinates=[[[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]],[[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]],[[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]],[[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],Array{Float64,1}[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]],
        extent=Extent(X=(0.0, 100.0), Y=(0.0, 100.0), Z=(0.0, 0.0)),
    ),(
        path=joinpath("shapelib_testcases", "test8.shp"),
        geomtype=PolylineZ,
        coordinates=[[[[1.0,1.0,3.35],[2.0,1.0,4.35],[2.0,2.0,5.35],[1.0,2.0,6.35],[1.0,1.0,7.35]]],[[[1.0,4.0,13.35],[2.0,4.0,14.35],[2.0,5.0,15.35],[1.0,5.0,16.35],[1.0,4.0,17.35]]],[[[1.0,7.0,23.35],[2.0,7.0,24.35],[2.0,8.0,25.35],[1.0,8.0,26.35],[1.0,7.0,27.35]]],[[[0.0,0.0,0.0],[0.0,100.0,1.0],[100.0,100.0,2.0],[100.0,0.0,3.0],[0.0,0.0,4.0]],[[10.0,20.0,5.0],[30.0,20.0,6.0],[30.0,40.0,7.0],[10.0,40.0,8.0],[10.0,20.0,9.0]],[[60.0,20.0,10.0],[90.0,20.0,11.0],[90.0,40.0,12.0],[60.0,40.0,13.0],[60.0,20.0,14.0]]]],
        extent=Extent(X=(0.0, 100.0), Y=(0.0, 100.0), Z=(0.0, 27.35)),
    ),(
        path=joinpath("shapelib_testcases", "test9.shp"),
        geomtype=PolylineM,
        coordinates=[[[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]],[[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]],[[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]],[[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],Array{Float64,1}[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]],
        extent=Extent(X=(0.0, 100.0), Y=(0.0, 100.0), Z=(0.0, 0.0)),
    ),(
        path=joinpath("shapelib_testcases", "test10.shp"),
        geomtype=Polygon,
        coordinates=[[[[[1.0,1.0],[2.0,1.0],[2.0,2.0],[1.0,2.0],[1.0,1.0]]]],[[[[1.0,4.0],[2.0,4.0],[2.0,5.0],[1.0,5.0],[1.0,4.0]]]],[[[[1.0,7.0],[2.0,7.0],[2.0,8.0],[1.0,8.0],[1.0,7.0]]]],[[[[0.0,0.0],[0.0,100.0],[100.0,100.0],[100.0,0.0],[0.0,0.0]],[[10.0,20.0],[30.0,20.0],[30.0,40.0],[10.0,40.0],[10.0,20.0]],[[60.0,20.0],[90.0,20.0],[90.0,40.0],[60.0,40.0],[60.0,20.0]]]]],
        extent=Extent(X=(0.0, 100.0), Y=(0.0, 100.0), Z=(0.0, 0.0)),
    ),(
        path=joinpath("shapelib_testcases", "test11.shp"),
        geomtype=PolygonZ,
        coordinates=[[[[[1.0,1.0,3.35],[2.0,1.0,4.35],[2.0,2.0,5.35],[1.0,2.0,6.35],[1.0,1.0,7.35]]]],[[[[1.0,4.0,13.35],[2.0,4.0,14.35],[2.0,5.0,15.35],[1.0,5.0,16.35],[1.0,4.0,17.35]]]],[[[[1.0,7.0,23.35],[2.0,7.0,24.35],[2.0,8.0,25.35],[1.0,8.0,26.35],[1.0,7.0,27.35]]]],[[[[0.0,0.0,0.0],[0.0,100.0,1.0],[100.0,100.0,2.0],[100.0,0.0,3.0],[0.0,0.0,4.0]],[[10.0,20.0,5.0],[30.0,20.0,6.0],[30.0,40.0,7.0],[10.0,40.0,8.0],[10.0,20.0,9.0]],[[60.0,20.0,10.0],[90.0,20.0,11.0],[90.0,40.0,12.0],[60.0,40.0,13.0],[60.0,20.0,14.0]]]]],
        extent=Extent(X=(0.0, 100.0), Y=(0.0, 100.0), Z=(0.0, 27.35)),
    ),(
        path=joinpath("shapelib_testcases", "test12.shp"),
        geomtype=PolygonM,
        coordinates=[[[[[1.0, 1.0], [2.0, 1.0], [2.0, 2.0], [1.0, 2.0], [1.0, 1.0]]]], [[[[1.0, 4.0], [2.0, 4.0], [2.0, 5.0], [1.0, 5.0], [1.0, 4.0]]]], [[[[1.0, 7.0], [2.0, 7.0], [2.0, 8.0], [1.0, 8.0], [1.0, 7.0]]]], [[[[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]], [[10.0, 20.0], [30.0, 20.0], [30.0, 40.0], [10.0, 40.0], [10.0, 20.0]], [[60.0, 20.0], [90.0, 20.0], [90.0, 40.0], [60.0, 40.0], [60.0, 20.0]]]]],
        extent=Extent(X=(0.0, 100.0), Y=(0.0, 100.0), Z=(0.0, 0.0)),
    ),(
        path=joinpath("shapelib_testcases/test13.shp"),
        geomtype=MultiPatch,
        coordinates=nothing,
        extent=Extent(X=(0.0, 100.0), Y=(0.0, 100.0), Z=(0.0, 27.35)),
        skip_check_mask = 93:100,
    )
]

# Visual plot check
# for t in test_tuples
#     if !(t.geomtype <: Union{Missing,MultiPatch})
#         @show t.path t.geomtype
#         sh = Shapefile.Handle(t.path)
#         p = sh.shapes
#         display(plot(p; opacity=.5))
#         sleep(1)
#     end
# end

points = [Point(1, 3), Point(2, 3), Point(2, 4), Point(1, 4)]
test_shapes = Dict(
    Point => Point(1, 2),
    PointM => PointM(1, 2, 3),
    PointZ => PointZ(1, 2, 3, 4),
    MultiPoint => MultiPoint(Rect(1, 3, 2, 4), points),
    MultiPointM => MultiPointM(Rect(1, 3, 2, 4), points, Interval(10.0, 40.0), [10.0, 20.0, 30.0, 40.0]),
    MultiPointZ => MultiPointZ(Rect(1, 3, 2, 4), points, Interval(1, 4), [1, 2, 3, 4], Interval(10.0, 40.0), [10.0, 20.0, 30.0, 40.0]),
    Polygon => Polygon(Rect(1, 3, 2, 4), [0], points),
    PolygonM => PolygonM(Rect(1, 3, 2, 4), [0], points, Interval(10.0, 40.0), [10.0, 20.0, 30.0, 40.0]),
    PolygonZ => PolygonZ(Rect(1, 3, 2, 4), [0], points, Interval(1, 4), [1, 2, 3, 4], Interval(10.0, 40.0), [10.0, 20.0, 30.0, 40.0]),
    Polyline => Polyline(Rect(1, 3, 2, 4), [0], points),
    PolylineM => PolylineM(Rect(1, 3, 2, 4), [0], points, Interval(10.0, 40.0), [10.0, 20.0, 30.0, 40.0]),
    PolylineZ => PolylineZ(Rect(1, 3, 2, 4), [0], points, Interval(1, 4), [1, 2, 3, 4], Interval(10.0, 40.0), [10.0, 20.0, 30.0, 40.0]),
    LineString => LineString{Point}(view(points, 1:4)),
    LinearRing => LinearRing{Point}(view(points, 1:4)),
    SubPolygon => SubPolygon([LinearRing{Point}(view(points, 1:4))]),
)

@testset "GeoInterface compatibility" begin
    foreach(values(test_shapes)) do s
        @test GeoInterface.testgeometry(s)
        @test GeoInterface.extent(s) isa GeoInterface.Extent
        plot(s)
    end
    @test_broken GeoInterface.testgeometry(MultiPatch(Rect(1, 3, 2, 4), [0], [1], points, Interval(1, 4), [1, 2, 3, 4]))

    @test GeoInterface.extent(Shapefile.Point(1.0, 2.0)) == Extents.Extent(X=(1.0, 1.0), Y=(2.0, 2.0))
    @test GeoInterface.extent(Shapefile.PointM(1.0, 2.0, 4.0)) == Extents.Extent(X=(1.0, 1.0), Y=(2.0, 2.0))
    @test GeoInterface.extent(Shapefile.PointZ(1.0, 2.0, 3.0, 4.0)) == Extents.Extent(X=(1.0, 1.0), Y=(2.0, 2.0), Z=(3.0, 3.0))
    @test GeoInterface.extent(test_shapes[Polygon]) == Extents.Extent(X=(1.0, 2.0), Y=(3.0, 4.0))
    @test GeoInterface.extent(test_shapes[PolygonM]) == Extents.Extent(X=(1.0, 2.0), Y=(3.0, 4.0))
    @test GeoInterface.extent(test_shapes[PolygonZ]) == Extents.Extent(X=(1.0, 2.0), Y=(3.0, 4.0), Z=(1.0, 4.0))
end

@testset "Loading Shapefiles" begin

for test in test_tuples
    for use_shx in (false, true)
        shp = if use_shx
            # this accesses .shp based on offsets in .shx
            stempath, ext = splitext(test.path)
            shxname = string(stempath, ".shx")
            Shapefile.Handle(joinpath(@__DIR__, test.path), joinpath(@__DIR__, shxname))
        else
            # use .shp only
            open(joinpath(@__DIR__, test.path)) do fd
                read(fd, Shapefile.Handle)
            end
        end
        shapes = unique(map(typeof, shp.shapes))
        @test GeoInterface.crs(shp) == nothing
        @test length(shapes) == 1
        @test length(shapes) == 1
        @test shapes[1] == test.geomtype
        @test eltype(shp.shapes) == Union{test.geomtype,Missing}
        # missing and MultiPatch are not covered by the GeoInterface
        if !(test.geomtype <: Union{Missing,Shapefile.MultiPatch})
            @test GeoInterface.coordinates.(shp.shapes) == test.coordinates
        end
        ext = test.extent
        @test shp.header.MBR == Shapefile.Rect(ext.X[1], ext.Y[1], ext.X[2], ext.Y[2])
        @test GeoInterface.extent(shp) == test.extent
        # Multipatch can't be plotted, but it's obscure anyway
        if !(test.geomtype == Shapefile.MultiPatch)
            plot(shp) # Just test that it actually plots
        end
    end
end


# Test all .shx files; the values in .shx must match the .shp offsets
test = test_tuples[1]
for test in test_tuples

    offsets = Int32[]
    contentlens = Int32[]

    # Get the shapefile's record offsets and contentlens
    shp = open(joinpath(@__DIR__, test.path)) do fd
        seek(fd, 32)
        shapeType = read(fd, Int32)
        seek(fd, 100)
        jltype = Shapefile.SHAPETYPE[shapeType]

        push!(offsets, position(fd))
        while (!eof(fd))

            num = bswap(read(fd, Int32))
            rlength = bswap(read(fd, Int32))
            shapeType = read(fd, Int32)
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
    shx =
        open(joinpath(@__DIR__, replace(test.path, r".shp$" => ".shx"))) do fd
            shx = read(fd, Shapefile.IndexHandle)
            for sIdx = 1:lastindex(shx.indices)
                @test shx.indices[sIdx].offset * 2 == offsets[sIdx]
                @test shx.indices[sIdx].contentlen * 2 + 8 == contentlens[sIdx]
            end
        end

end

end  # @testset "Loading Shapefiles"

include("table.jl")
include("writer.jl")

cleanup()
