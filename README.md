# Shapefile

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaGeo.github.io/Shapefile.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaGeo.github.io/Shapefile.jl/dev)
[![CI](https://github.com/JuliaGeo/Shapefile.jl/workflows/CI/badge.svg)](https://github.com/JuliaGeo/Shapefile.jl/actions?query=workflow%3ACI)
[![CI](https://github.com/JuliaGeo/Shapefile.jl/workflows/CI/badge.svg)](https://github.com/JuliaGeo/Shapefile.jl/actions?query=workflow%3ACI)

This library supports reading and writing ESRI Shapefiles in pure Julia.

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
2-element Vector{Vector{Vector{Vector{Float64}}}}:
 [[[20.0, 20.0], [20.0, 30.0], [30.0, 30.0], [20.0, 20.0]]]
 [[[0.0, 0.0], [100.0, 0.0], [100.0, 100.0], [0.0, 100.0], [0.0, 0.0]]]
```

## Alternative packages

If you want another lightweight pure Julia package for reading feature files, consider
also [GeoJSON.jl](https://github.com/JuliaGeo/GeoJSON.jl).

For more fully featured support for reading and writing geospatial data, at the
cost of a larger binary dependency, look at [ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl/) 
or [GeoDataFrames.jl](https://github.com/evetion/GeoDataFrames.jl).
