#
# Unit Testing for Shapefile writer
#

@testset "Shapefile (.shp) writers" begin

    @testset "write/read round trip" begin
        # missing
        file = tempname()
        Shapefile.write(file, missing)
        t = Shapefile.Table(file)
        @test ismissing(only(t.geometry))

        # geometry
        file = tempname()
        Shapefile.write(file, Point(0,0))
        t = Shapefile.Table(file)
        @test only(t.geometry) == Point(0,0)

        ps = [Point(0,0), Point(0.5,2), Point(2.2,2.2), Point(0,0)]
        box = Rect(0.0, 0.0, 2.2, 2.2)

        # linestring as polyline
        geom = LineString{Point}(view(ps, 1:3))
        file = tempname()
        Shapefile.write(file, geom)
        t = Shapefile.Table(file)
        @test only(t.geometry) == Polyline(box, [0], ps[1:3])

        # subpolygon as polygon
        geom = SubPolygon([LinearRing{Point}(view(ps, 1:4))])
        file = tempname()
        Shapefile.write(file, geom)
        t = Shapefile.Table(file)
        @test only(t.geometry) == Polygon(box, [0], ps)

        # feature
        struct F end
        GI.trait(::F) = GI.FeatureCollectionTrait()
        GI.isfeature(::F) = true
        GI.geometry(::F) = Point(0,0)
        GI.properties(::F) = (one=1, two=2)
        file = tempname()
        Shapefile.write(file, F())
        t = Shapefile.Table(file)
        @test t.geometry == [Point(0,0)]
        @test t.one == [1]
        @test t.two == [2]

        # geometry collection
        struct GC end
        GI.geomtrait(::GC) = GI.GeometryCollectionTrait()
        GI.ncoord(::GI.GeometryCollectionTrait, geom::GC) = 2
        GI.ngeom(::GI.GeometryCollectionTrait, geom::GC) = 2
        GI.getgeom(::GI.GeometryCollectionTrait, geom::GC) = [missing, Point(1,1)]
        file = tempname()
        Shapefile.write(file, GC())
        t = Shapefile.Table(file)
        @test all(isequal.(t.geometry, [missing, Point(1,1)]))

        # feature collection
        struct FC end
        GI.geomtrait(::FC) = GI.FeatureCollectionTrait()
        GI.isfeaturecollection(::FC) = true
        GI.getfeature(::GI.FeatureCollectionTrait, ::FC, i) = F()
        GI.nfeature(::GI.FeatureCollectionTrait, ::FC) = 2
        file = tempname()
        Shapefile.write(file, FC())
        t = Shapefile.Table(file)
        @test t.geometry == [Point(0,0), Point(0,0)]
        @test t.one == [1, 1]
        @test t.two == [2, 2]

        # feature collection without properties
        struct NoProps end
        feats = [(; geometry=Point(0,0)), (; geometry=Point(1,1))]
        GI.geomtrait(::NoProps) = GI.FeatureCollectionTrait()
        GI.isfeaturecollection(::NoProps) = true
        GI.getfeature(::GI.FeatureCollectionTrait, ::NoProps, i) = feats[i]
        GI.nfeature(::GI.FeatureCollectionTrait, ::NoProps) = length(feats)
        file = tempname()
        Shapefile.write(file, NoProps())
        t = Shapefile.Table(file)
        @test t.geometry == [Point(0,0), Point(1,1)]

        # table (with missing)
        tbl = [
            (geo=Point(0,0), feature=1),
            (geo=Point(1,1), feature=2),
            (geo=missing, feature=3),
            (geo=Point(2,2), feature=missing)
        ]
        file = tempname()
        Shapefile.write(file, tbl)
        t = Shapefile.Table(file)
        @test all(isequal.(t.geometry, [Point(0,0), Point(1,1), missing, Point(2,2)]))
        @test all(isequal.(t.feature, [1, 2, 3, missing]))

        # iterator of geometries
        geoms = (Point(i, i) for i in 1:10)
        file = tempname()
        Shapefile.write(file, geoms)
        t = Shapefile.Table(file)
        @test t.geometry == Point.(1:10, 1:10)

        # iterator of features
        file = tempname()
        Shapefile.write(file, (F() for i in 1:10))
        t = Shapefile.Table(file)
        @test t.geometry == [Point(0,0) for i in 1:10]
    end

for i in eachindex(test_tuples)[1:end-1] # We don't write 15 - multipatch

    i == 2 && continue # skip case of only missing data

    test = test_tuples[i]
    path = joinpath(@__DIR__, test.path)
    shp = Shapefile.Handle(path)
    Shapefile.write("testshape", shp.shapes; force=true)

    @testset "shx indices match" begin
        ih1 = read(Shapefile._shape_paths(path).shx, Shapefile.IndexHandle)
        ih2 = read(Shapefile._shape_paths("testshape").shx, Shapefile.IndexHandle)
        @test ih1.indices == ih2.indices
    end
    @testset "shx headers match" begin
        h1 = read(Shapefile._shape_paths(path).shx, Shapefile.Header)
        h2 = read(Shapefile._shape_paths("testshape").shx, Shapefile.Header)
        if !haskey(test, :skip_check_mask)
            @test h1 == h2
        end
    end
    @testset "shx bytes match" begin
        r1 = read("testshape.shx")
        r2 = read(Shapefile._shape_paths(path).shx)
        if haskey(test, :skip_check_mask)
            inds = map(eachindex(r1)) do i
                !(i in test.skip_check_mask)
            end
            @test r1[inds] == r2[inds]
        else
            findall(r1 .!= r2)
            @test r1 == r2
        end
    end

    @testset "shp headers match" begin
        h1 = read("testshape.shp", Shapefile.Header)
        h2 = read(path, Shapefile.Header)
        if !haskey(test, :skip_check_mask)
            @test h1 == h2
        end
    end
    @testset "shp bytes match" begin
        r1 = read("testshape.shp")
        r2 = read(path)
        if haskey(test, :skip_check_mask)
            inds = map(eachindex(r1)) do i
                !(i in test.skip_check_mask)
            end
            @test r1[inds] == r2[inds]
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
