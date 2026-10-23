using Shapefile
using Test

@testset "Missing table component paths" begin
    mktempdir() do dir
        for extension in ("", ".shp")
            # Neither component exists: report the geometry file first.
            stem = joinpath(dir, isempty(extension) ? "bare" : "explicit")
            path = stem * extension
            @test_throws ArgumentError("File not found: $(stem).shp") Shapefile.Table(path)

            # An existing attribute file must not be named as the missing file.
            touch(stem * ".dbf")
            @test_throws ArgumentError("File not found: $(stem).shp") Shapefile.Table(path)
        end

        # Keep the existing diagnostic for an absent attribute file.
        stem = joinpath(dir, "geometry_only")
        touch(stem * ".shp")
        for extension in ("", ".shp")
            @test_throws ArgumentError("File not found: $(stem).dbf") Shapefile.Table(stem * extension)
        end
    end
end
