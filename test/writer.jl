#
# Unit Testing for Shapefile writer
#

@testset "Shapefile (.shp) writers" begin

for i in eachindex(test_tuples)[1:end-1] # We dont write 15 - multipatch
    #
    # Read the shapefile into memory and write it into a temporary IO buffer
    #
    test = test_tuples[i]
    path = joinpath(@__DIR__, test.path)
    shp = Shapefile.Handle(path)
    Shapefile.write("testshape", shp.shapes; force=true)
    fieldnames(Shapefile.Header)
    @testset "compare headers" begin
        h1 = read("testshape.shp", Shapefile.Header)
        h2 = read(path, Shapefile.Header)
        if !haskey(test, :skip_check_mask)
            @test h1 == h2
        end
    end
    @testset "compare bytes" begin
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
    @testset "compare points" begin
        shp1 = Shapefile.Handle(path)
        shp2 = Shapefile.Handle("testshape.shp")
        shp1.shapes
        shp2.shapes
        @test all(map(shp1.shapes, shp2.shapes) do s1, s2
            ismissing(s1) && ismissing(s2) || s1 == s2
        end)
    end
end

end
