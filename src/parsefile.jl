#
# Parse Shapefiles into GeoInterface FeatureCollection
#
function GeoInterface.properties(df::DataFrames.AbstractDataFrame)
    properties = Vector{Dict}(undef,0)
    for row in eachrow(df)
        push!(properties, Dict([string(p[1])=>p[2] for p in pairs(row)]))
    end
    properties
end

"""
parse_shapefile(fname::AbstractString)

"""
function parse_shapefile(shapefielName::AbstractString)
    # determine file existence
    filePath,fileExt = splitext(shapefielName)
    filePath,fileName = splitdir(filePath)

    # Read indics
    if isfile(joinpath(filePath,fileName*".shx"))
        shx = open(joinpath(filePath,fileName*".shx")) do io
            read(io, Shapefile.IndexHandle)
        end
    end

    # Read geometries
    if isfile(joinpath(filePath,fileName*".shp"))
        shp = open(joinpath(filePath,fileName*".shp")) do io
            read(io, Shapefile.Handle)
        end
    end

    # Read properties
    if isfile(joinpath(filePath,fileName*".dbf"))
        dbf = GeoInterface.properties(DBFTables.read_dbf(joinpath(filePath,fileName*".dbf")))
    end

    # Assertions
    # TODO: matching size of each source

    # TODO: Build GeoInterface.FeatureCollection
    #   FeatureCollection = [Feature, Feature, ...]
    #   Where Feature = [geometries, properties]

end
