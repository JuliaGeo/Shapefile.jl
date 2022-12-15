#
# Unit Testing for Shapefile writer
#

@testset "Shapefile (.shp) writers" begin

    @testset "write/read round trip" begin
        struct T end
        GCT = GeoInterface.GeometryCollectionTrait
        GeoInterface.isgeometry(::T) = true
        GeoInterface.geomtrait(::T) = GCT()
        GeoInterface.ngeom(::GCT, ::T) = 1
        GeoInterface.getgeom(::GCT, ::T, i) = Point(1,2)
        GeoInterface.crs(::GCT, ::T) = EPSG(4326)
        # test for warning before loading ArchGDAL
        @test_throws MethodError convert(GeoFormatTypes.ESRIWellKnownText{GeoFormatTypes.CRS}, EPSG(4326))
        @test_warn ".prj write failure" Shapefile.write("roundtrip.shp", T(); force=true)
        @test !isfile("roundtrip.prj")

        # test for no warning after loading ArchGDAL
        using ArchGDAL
        @test_nowarn Shapefile.write("roundtrip.shp", T(); force=true)
        @test isfile("roundtrip.prj")

        # Uncomment when DBFTables.jl write lands:
        # t = Shapefile.Table("roundtrip.shp")
        # @test first(t.geometry) == Point(1,2)
        # @test GeoInterface.crs(t) == convert(GeoFormatTypes.ESRIWellKnownText{GeoFormatTypes.CRS}, EPSG(4326))
    end

for i in eachindex(test_tuples)[1:end-1] # We dont write 15 - multipatch

    test = test_tuples[i]
    path = joinpath(@__DIR__, test.path)
    shp = Shapefile.Handle(path)
    Shapefile.write("testshape", shp.shapes; force=true)

    @testset "shx indices match" begin
        ih1 = read(Shapefile._shape_paths(path).shx, Shapefile.IndexHandle)
        ih2 = read(Shapefile._shape_paths("testshape").shx, Shapefile.IndexHandle)
        @test ih1.indices == ih2.indices
    end
    @testset "shp headers match" begin
        h1 = read("testshape.shp", Shapefile.Header)
        h2 = read(path, Shapefile.Header)
        h3 = read(Shapefile._shape_paths("testshape").shx, Shapefile.Header)
        if !haskey(test, :skip_check_mask)
            @test h1 == h2 == h3
        end
    end
    @testset "shp bytes match" begin
        r1 = read("testshape.shp")
        r2 = read(path)
        if haskey(test, :skip_check_mask)
            inds = map(eachindex(r1)) do i
                !(i in test.skip_check_mask)
            end
            r1[inds] == r2[inds]
        else
            findall(r1 .!= r2)
            @test r1 == r2
        end
    end
    @testset "shapes match" begin
        shp1 = Shapefile.Handle(path)
        shp2 = Shapefile.Handle("testshape.shp")
        shp3 = Shapefile.Handle("testshape.shp", "testshape.shx")
        @test all(map(shp1.shapes, shp2.shapes) do s1, s2
            ismissing(s1) && ismissing(s2) || s1 == s2
        end)
    end
    @testset "prjs match" begin
        prjpath = replace(path, ".shp" => ".prj")
        if isfile(prjpath)
            prj1 = read(prjpath, String)
            prj2 = read("testshape.prj", String)
            @test prj1 == prj2
        end
    end
end

end
