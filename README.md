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

# the metadata can be converted to other Tables such as DataFrame
using DataFrames
df = DataFrame(table)
```

Shapefiles can contain multiple parts for each shape entity.
Use `GeoInterface.coordinates` to fully decompose the shape data into parts.

```julia
# Example of converting the 1st shape of the file into parts (array of coordinates)
julia> GeoInterface.coordinates(Shapefile.shape(first(table)))
2-element Array{Array{Array{Array{Float64,1},1},1},1}:
 Array{Array{Float64,1},1}[Array{Float64,1}[[20.0, 20.0], ...]]
 Array{Array{Float64,1},1}[Array{Float64,1}[[0.0, 0.0], ...]]
```

## Alternative packages
If you want another lightweight pure Julia package for reading feature files, consider
also [GeoJSON.jl](https://github.com/JuliaGeo/GeoJSON.jl).

For much more fully featured support for reading and writing geospatial data, at the
cost of a larger binary dependency, look at [GDAL.jl](https://github.com/JuliaGeo/GDAL.jl)
or [ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl/) packages.
The latter builds a higher level API on top of GDAL.jl.
