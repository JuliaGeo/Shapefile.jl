#
# Parse Shapefiles into GeoInterface FeatureCollection
#
function GeoInterface.properties(df::DataFrames.AbstractDataFrame)
    properties = Vector{Dict}(undef,0)
    for row in DataFrames.eachrow(df)
        push!(properties, Dict([string(p[1])=>p[2] for p in pairs(row)]))
    end
    properties
end

"""
parse(shapefielname::AbstractString)

It will parse Shapefile file and DBF files into `FeatureCollection`, the index file is also parsed but used for checking records lenght only.
The files has to be in the same directory.
"""
function parse(shapefileName::AbstractString)
    # determine file existence
    filePath,fileExt = splitext(shapefileName)
    filePath,fileName = splitdir(filePath)

    hasIndex = isfile(joinpath(filePath,fileName*".shx"))
    hasDBase = isfile(joinpath(filePath,fileName*".dbf"))

    # Variable Initialization
    shp = nothing
    shx = nothing
    dbf = nothing

    # Read geometries
    if isfile(joinpath(filePath,fileName*".shp"))
        shp = open(joinpath(filePath,fileName*".shp")) do io
            read(io, Shapefile.Handle)
        end
    else
        @error "ESRI Shapefile is required."
    end
    numFeatures = length(shp.shapes)

    # Read indics
    if hasIndex
        shx = open(joinpath(filePath,fileName*".shx")) do io
            read(io, Shapefile.IndexHandle)
        end
        @assert numFeatures == length(shx.indices) "Shapefile Index file (.shx) must have the same number of records as the Shapefile (.shp)"
    end

    # Read properties
    if hasIndex
        dbf = GeoInterface.properties(DBFTables.read_dbf(joinpath(filePath,fileName*".dbf")))
        @assert numFeatures == length(dbf) "DBase III file (.dbf) must have the same number of records as the Shapefile (.shp)"
    else
        dbf = fill(nothing,numFeatures)
    end

    # Build GeoInterface.FeatureCollection
    #   FeatureCollection = ([Feature, Feature, ...],bbox,crs), where Feature = (geometries, properties)
    shapefileFeatures = Array{GeoInterface.Feature}(undef,numFeatures)
    for idx = 1:numFeatures
        shapefileFeatures[idx] = GeoInterface.Feature(
                                    shp.shapes[idx],
                                    dbf[idx]
                                )
    end

    #TODO: Figure out how to order the shp.MBR values for bbox
    # bbox = [shp.MBR.left, shp.MBR.bottom, shp.MBR.right, shp.MBR.top]
    # or
    # bbox = [shp.MBR.bottom, shp.MBR.left, shp.MBR.top, shp.MBR.right]
    return GeoInterface.FeatureCollection(
        shapefileFeatures,
        nothing,
        nothing
    )

end
