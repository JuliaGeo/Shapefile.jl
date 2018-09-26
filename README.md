# Shapefile

[![Build Status](https://travis-ci.org/JuliaGeo/Shapefile.jl.svg)](https://travis-ci.org/JuliaGeo/Shapefile.jl)
[![Shapefile](https://pkg.julialang.org/badges/Shapefile_0.6.svg)](https://pkg.julialang.org/detail/Shapefile)
[![Shapefile](https://pkg.julialang.org/badges/Shapefile_0.7.svg)](https://pkg.julialang.org/detail/Shapefile)

This library supports reading ESRI Shapefiles in pure Julia. Note that currently only
the `.shp` is read, not `.shx` or `.dbf`. This means the feature geometry can be read,
but no attribute information is associated to it.

## Quick Start
Basic example of reading a shapefile from test cases:

```julia
using Shapefile

path = joinpath(dirname(pathof(Shapefile)),"..","test","shapelib_testcases","test.shp")

handle = open(path, "r") do io
    read(io, Shapefile.Handle)
end
```

The `Shapefile.Handle` structure contains shapes and metadata.
List of the `Shapefile.Handle` field names:

```julia
julia> fieldnames(typeof(handle))
8-element Array{Symbol,1}:
 :code
 :length
 :version
 :shapeType
 :MBR
 :zrange
 :mrange
 :shapes
```

Shapefiles can contain multiple parts for each shape entity.
Use `GeoInterface.coordinates` to fully decompose the shape data into parts.

```julia
# Example of converting the 1st shape of the file into parts (array of coordinates)
julia> GeoInterface.coordinates(handle.shapes[1])
2-element Array{Array{Array{Array{Float64,1},1},1},1}:
 Array{Array{Float64,1},1}[Array{Float64,1}[[20.0, 20.0], ...]]
 Array{Array{Float64,1},1}[Array{Float64,1}[[0.0, 0.0], ...]]
```

## Alternative packages
If you want another lightweight pure Julia package for reading feature files, consider
also [GeoJSON.jl](https://github.com/JuliaGeo/GeoJSON.jl). It will also give access to
the attribute information.

For much more fully featured support for reading and writing geospatial data, at the
cost of a larger binary dependency, look at [GDAL.jl](https://github.com/JuliaGeo/GDAL.jl)
or [ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl/) packages.
The latter builds a higher level API on top of GDAL.jl.
