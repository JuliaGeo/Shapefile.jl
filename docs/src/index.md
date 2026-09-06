```@meta
CurrentModule = Shapefile
```

# Shapefile

Documentation for [Shapefile](https://github.com/JuliaGeo/Shapefile.jl).

## Missing measures

Shapefile represents measures with no data as `Float64` sentinel values strictly
below `-1e38`. These values are retained when reading, including the bounds of
measure ranges. If an optional measure block is absent, its measures and range
bounds are filled with `-1e39`.

When writing GeoInterface geometries, `missing` measures are encoded as `-1e39`.
Z geometries without measures are written with no-data M fields. Measure ranges
in records and file headers exclude no-data values; if all measures are no-data,
both bounds are written as `-1e39`. The X, Y, and Z coordinates are unaffected.

```@index
```

```@autodocs
Modules = [Shapefile]
```
