#
# Unit Testing for Shapefile writer
#

@testset "Shapefile (.shp) writers" begin


for test in test_tuples
    
    #
    # Read the shapefile into memory and write it into a temporary IO buffer
    #
    shp = open(joinpath(@__DIR__, test.path)) do fd
        read(fd, Shapefile.Handle)
    end
    test_io = IOBuffer()
    write(test_io, Shapefile.Handle, shp.shapes)
    test_bytes = take!(test_io)

    # Read the original file as bytes for byte-to-byte comparison
    match_bytes = open(joinpath(@__DIR__, test.path)) do fd
        read(fd)
    end
    
    #
    # Load in some testing exception, because the test data is partially invalid.
    #
    if haskey(test,:skip_check_mask)
        for idc in test.skip_check_mask
            match_bytes[idc] .= 0
            test_bytes[idc] .= 0
        end 
    end

    @test all(test_bytes .== match_bytes)    
end

end
