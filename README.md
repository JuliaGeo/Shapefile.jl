# Shapefile  

[![Build Status](https://travis-ci.org/JuliaGeo/Shapefile.jl.svg)](https://travis-ci.org/JuliaGeo/Shapefile.jl)
[![Shapefile](http://pkg.julialang.org/badges/Shapefile_0.5.svg)](http://pkg.julialang.org/detail/Shapefile)
[![Shapefile](http://pkg.julialang.org/badges/Shapefile_0.6.svg)](http://pkg.julialang.org/detail/Shapefile)

This library support reading Shapefile in the pure Julia programming language
## Quick Start
Basic example of reading a shapefile from test cases:
```Julia
using Shapefile
shapeFileName = joinpath(Pkg.dir(), "Shapefile", "test", "shapelib_testcases", "test.shp")
shapeFileHandle = open(shapeFileName,"r") do io
    read(io, Shapefile.Handle)
end
```

The Shapefile's Handle structure contains shapes and metadata. List of the Shapefile's Handle field names:

```Julia
julia> fieldnames(shapeFileHandle)
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

Shapefile can contain multiple parts for each shape entity. Use `GeoInterface.coordinates` to fully decompose the shape data into parts.

```Julia
# Example of converting the 1st shape of the file into parts (array of coordinates)
julia> GeoInterface.coordinates(shapeFileHandle.shapes[1])
2-element Array{Array{Array{Array{Float64,1},1},1},1}:
 Array{Array{Float64,1},1}[Array{Float64,1}[[20.0, 20.0], ...]]
 Array{Array{Float64,1},1}[Array{Float64,1}[[0.0, 0.0], ...]]
```

