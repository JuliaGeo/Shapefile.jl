# Shapefile

[![Build Status](https://travis-ci.org/JuliaGeo/Shapefile.jl.svg)](https://travis-ci.org/JuliaGeo/Shapefile.jl)

This library supports reading ESRI Shapefiles in pure Julia.

## Quick Start
Basic example of reading a shapefile from test cases:

```julia
using Shapefile

path = joinpath(dirname(pathof(Shapefile)),"..","test","shapelib_testcases","test.shp")
table = Shapefile.Table(path)

# if you only want the geometries and not the metadata in the DBF file
geoms = Shapefile.shapes(table)

# whole columns can be retrieved by their name
table.Descriptio  # => Union{String, Missing}["Square with triangle missing", "Smaller triangle", missing]

# example function that iterates over the rows and gathers shapes that meet specific criteria
function selectshapes(table)
    geoms = empty(Shapefile.shapes(table))
    for row in table
        if !ismissing(row.TestDouble) && row.TestDouble < 2000.0
            push!(geoms, Shapefile.shape(row))
        end
    end
    return geoms
end
```

The GeometryBasics types bring in metadata support that allow storing metadata into a NamedTuple along with the geometry.
```julia
# Example of working with metadata
using GeometryBasics


# read the shape
shape = Shapefile.shape(first(table)));

# get the shape without it's metadata
shape_mf = metafree(shape)

# get the metadata as a NamedTuple
shape_meta = meta(shape)

# the metadata can be converted to other Tables such as DataFrame
using DataFrames
df = DataFrame(table)

df_sp = DataFrame(geoms)
```

## Alternative packages
If you want another lightweight pure Julia package for reading feature files, consider
also [GeoJSON.jl](https://github.com/JuliaGeo/GeoJSON.jl).

For much more fully featured support for reading and writing geospatial data, at the
cost of a larger binary dependency, look at [GDAL.jl](https://github.com/JuliaGeo/GDAL.jl)
or [ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl/) packages.
The latter builds a higher level API on top of GDAL.jl.
