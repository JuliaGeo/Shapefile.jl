#-----------------------------------------------------------------------------# Writer
# Pre-processing for writing arbitrary objects as shapefile.
# 1) Get `geoms` as iterator
# 2) Get `features` (Tables.jl table) that matches `geoms`.
# 3) Get CRS as GeoFormatTypes.ESRIWellKnownText
"""
    Writer(geoms, tbl = Shapefile.emptytable(geoms), crs = nothing)

Prepared data for writing as shapefile.
- `geoms` must be an iterator where elements satisfy `GeoInterface.isgeometry(x)` or `ismissing(x)`.
- `tbl` must be a Tables.jl table of features associated with the `geoms`.
- `crs` can be `nothing` or something that can be converted to `GeoFormatTypes.ESRI.WellKnownText{GeoFormatTypes.CRS}`.
"""
struct Writer
    geoms       # iterator of geometries (.shp/.shx)
    features    # Tables.jl table with same number of rows as geoms (.dbf)
    crs::Union{Nothing, GFT.ESRIWellKnownText{GFT.CRS}}  # (.prj)

    function Writer(geoms, feats = emptytable(geoms), crs=nothing)
        crs = if isnothing(crs)
            nothing
        else
            try
                convert(GFT.ESRIWellKnownText{GFT.CRS}, crs)
            catch
                @warn "Could not convert CRS of type `$(typeof(crs))` to " *
                "`GeoFormatTypes.ESRIWellKnownText{GeoFormatTypes.CRS}`.  `using ArchGDAL` may " *
                "load the necessary `Base.convert` method.  The CRS WILL NOT BE SAVED as a .prj file."
                nothing
            end
        end

        Tables.istable(feats) || error("Provided feature table (of type $(typeof(feats))) is not a valid Tables.jl table.")

        all(x -> GI.isgeometry(x) || ismissing(x), geoms) || error("Not all geoms satisfy `GeoInterface.isgeometry`.")

        ngeoms = sum(1 for _ in geoms)
        nfeats = sum(1 for _ in Tables.rows(feats))

        ngeoms == nfeats || error("Number of geoms does not match number of features.  Found: $ngeoms ≠ $nfeats.")

        new(geoms, feats, crs)
    end
end

emptytable(n::Integer) = [(;all_missing=missing) for _ in 1:n]
emptytable(itr) = [(;all_missing=missing) for _ in itr]


function get_writer(obj)
    crs = try; GI.crs(obj); catch; nothing; end

    if GI.isgeometry(obj) || ismissing(obj)
        return Writer([obj], emptytable(1), crs)
    elseif GI.isfeature(obj)
        return Writer([GI.geometry(obj)], [GI.properties(obj)], crs)
    elseif GI.trait(obj) isa GI.AbstractGeometryCollectionTrait
        geoms = GI.getgeom(obj)
        return Writer(geoms, emptytable(geoms), crs)
    elseif GI.trait(obj) isa GI.AbstractFeatureCollectionTrait
        geoms = map(GI.geometry, GI.getfeature(obj))
        feats = Tables.dictcolumntable(map(GI.properties, GI.getfeature(obj)))
        return Writer(geoms, feats, crs)
    elseif Tables.istable(obj)
        tbl = getfield(Tables.dictcolumntable(obj), :values)  # an OrderedDict
        geomfields = findall(tbl) do data
            all(x -> ismissing(x) || GI.isgeometry(x), data) && any(!ismissing, data)
        end
        if length(geomfields) > 1
            @warn "Multiple geometry columns detected: $geomfields. $(geomfields[1]) will be used " *
                  "and the rest discarded."
        end
        geoms = :geometry in keys(tbl) ? tbl[:geometry] : tbl[geomfields[1]]
        foreach(x -> delete!(tbl, x), geomfields)  # drop unused geometry columns
        tbl = isempty(tbl) ? emptytable(geoms) : tbl
        return Writer(geoms, tbl, crs)
    elseif all(GI.isgeometry, obj)
        return Writer(obj, emptytable(obj), crs)
    elseif all(GI.isfeature, obj)
        return Writer(map(GI.geometry, obj), map(GI.properties, obj), crs)
    else
        error("Shapefile.jl cannot determine how to write data from `$(typeof(obj))`.")
    end
end

#-----------------------------------------------------------------------------# write `Writer`
"""
    write(path::AbstractString, w::Shapefile.Writer; force=false)

See `?Shapefile.Writer` for details.
"""
function write(path::AbstractString, o::Writer; force=false)
    geoms, tbl, crs = o.geoms, o.features, o.crs

    paths = _shape_paths(path)
    if isfile(paths.shp)
        if force
            rm(paths.shp)
        else
            throw(ArgumentError("File already exists at `$(paths.shp)`. Use `force=true` to write anyway."))
        end
    end
    # Initialisation
    shx_indices = IndexRecord[]
    bytes = 0
    first_geom = true
    shapecode = SHAPECODE[Missing]
    mbr = Rect(0.0, 0.0, 0.0, 0.0)
    zrange = Interval(0.0, 0.0)
    mrange = Interval(0.0, 0.0)

    # Open the .shp file as an IO stream
    io = open(paths.shp, "a+")

    # Write an empty header
    # We go back later and write it properly later, so we don't have to precalculate everything.
    dummy_header = Header(; filesize=0, shapecode, mbr, zrange, mrange)
    bytes += Base.write(io, dummy_header)

    # Detect the shape type code from the first available geometry
    # There can only be one shape type in the file.
    # If all values are missing, the shape type is Missing
    if iterate(skipmissing(geoms)) == nothing
        trait = Missing
        hasz = hasm = false
    else
        geom1 = first(skipmissing(geoms))
        GI.isgeometry(geom1) || error("$(typeof(geom1)) is not a geometry")
        trait = GI.geomtrait(geom1)
        if trait isa GI.GeometryCollectionTrait
            throw(ArgumentError("Geometry collections or `MultiPatch` cannot currently be written using Shapefile.jl"))
        end
        hasz = GI.is3d(geom1)
        hasm = GI.ismeasured(geom1)
        shapecode = if hasz
            SHAPECODE[TRAITSHAPE_Z[typeof(trait)]]
        elseif hasm
            SHAPECODE[TRAITSHAPE_M[typeof(trait)]]
        else
            SHAPECODE[TRAITSHAPE[typeof(trait)]]
        end
    end

    # Write the geometry data into io
    for (num, geom) in enumerate(geoms)
        (ismissing(geom) || trait === GI.geomtrait(geom)) || throw(ArgumentError("Shapefiles can only contain geometries of the same type"))

        # One-based record number; Increment from 0, and increment after record.
        rec_bytes = 0
        rec_start = bytes
        calc_rec_bytes = sizeof(Int32) # shape code

        # Write record number
        bytes += Base.write(io, hton(Int32(num)))

        # Shortcut if the geom is missing
        if ismissing(geom)
            bytes += Base.write(io, hton(Int32(calc_rec_bytes ÷ 2)))
            rec_bytes += Base.write(io, SHAPECODE[Missing])
        else
            # Calculate record size
            if trait isa GI.PointTrait
                calc_rec_bytes += sizeof(Float64) * 2 # point values
                if hasz
                    calc_rec_bytes += sizeof(Float64) # z values
                end
                if hasm
                    calc_rec_bytes += sizeof(Float64) # measures
                end
            else
                n = GI.npoint(geom)
                calc_rec_bytes += sizeof(Rect) # Rect
                calc_rec_bytes += sizeof(Int32) # num points
                calc_rec_bytes += sizeof(Float64) * n * 2 # point values
                if hasz
                    calc_rec_bytes += sizeof(Interval) # z interval
                    calc_rec_bytes += sizeof(Float64) * n # z values
                end
                if hasm
                    calc_rec_bytes += sizeof(Interval) # m interval
                    calc_rec_bytes += sizeof(Float64) * n # measures
                end
                numparts = _nparts(trait, geom)
                if !isnothing(numparts)
                    calc_rec_bytes += sizeof(Int32) # num parts
                    calc_rec_bytes += sizeof(Int32) * numparts # parts offsets
                end
            end

            # length: measured in 16 bit increments, so divid by 2
            bytes += Base.write(io, hton(Int32(calc_rec_bytes ÷ 2)))
            # code
            rec_bytes += Base.write(io, shapecode)
            # geometry
            geom_bytes, geom_mbr, geom_zrange, geom_mrange = _write(io, trait, geom)
            rec_bytes += geom_bytes

            if first_geom
                first_geom = false
                mbr = geom_mbr
                zrange = geom_zrange
                mrange = geom_mrange
            else
                mbr = union(mbr, geom_mbr)
                zrange = union(zrange, geom_zrange)
                mrange = union(mrange, geom_mrange)
            end

        end

        # Check we precalculated the same number of bytes that we wrote
        @assert rec_bytes == calc_rec_bytes

        # Indices for .shx file
        offset = rec_start ÷ 2 # 16 bit words
        rec_len = rec_bytes ÷ 2 # 16 bit words
        push!(shx_indices, IndexRecord(offset, rec_len))

        # Record Header
        # 32-bits (4 bytes) Record Number + 32-bits (4 bytes) Content length = 8 bytes
        bytes += rec_bytes
    end

    # Finally write the correct header at the start of the file
    header = Header(; filesize=bytes ÷ 2, shapecode, mbr, zrange, mrange)
    seek(io, 0)
    Base.write(io, header)

    # Close .shp file
    close(io)

    # Write .shx file
    index_handle = IndexHandle(header, shx_indices)
    Base.write(paths.shx, index_handle)

    # Write .dbf file
    DBFTables.write(paths.dbf, tbl)

    # Write .prj file
    if !isnothing(crs)
        try
            Base.write(paths.prj, convert(GFT.ESRIWellKnownText{GFT.CRS}, crs).val)
        catch
            @warn ".prj write failure: Could not convert CRS of type `$(typeof(crs))` to " *
            "`GeoFormatTypes.ESRIWellKnownText{GeoFormatTypes.CRS}`.  `using ArchGDAL` may " *
            "load the necessary `Base.convert` method."
        end
    end

    return bytes
end

"""
    write(path::AbstractString, obj; force=false)

Write `obj` in the shapefile (.shp, .shx, .dbf, and possibly .prj files) format.  `obj` must satisfy
one of:

1. `GeoInterface.isgeometry(obj)`.
2. `GeoInterface.trait(obj) <: GeoInterface.AbstractGeometryCollectionTrait.`
3. `GeoInterface.trait(obj) <: GeoInterface.AbstractFeatureCollectionTrait`.
4. `Tables.istable(obj)` and one of the columns of `obj` is a geometry.
5. An iterator of elements that satisfy `GeoInterface.isgeometry(element)`.
"""

write(path::AbstractString, obj; force=false) = write(path, get_writer(obj); force)


# Geometry writing
_write(io::IO, geom; kw...) = _write(io::IO, GI.geomtrait(geom), geom; kw...)
function _write(io::IO, ::Nothing, obj; kw...)
    throw(ArgumentError("trying to write an object that is not a geometry: $(typeof(obj))"))
end
function _write(io::IO, trait::GI.AbstractGeometryTrait, geom; kw...)
    bytes = Int64(0)
    mbr = _calc_mbr(geom)
    bytes += Base.write(io, mbr)
    numparts = _nparts(trait, geom)
    if !isnothing(numparts)
        bytes += Base.write(io, numparts)
    end
    numpoints = Int32(GI.npoint(geom))
    bytes += Base.write(io, numpoints)

    # Polygons list ring start locations as "parts"
    if !isnothing(numparts)
        offset = Int32(0)
        for part in _get_parts(trait, geom)
            bytes += Base.write(io, offset)
            offset += Int32(GI.npoint(part))
        end
    end
    # write x/y part of points
    for point in GI.getpoint(geom)
        x, y = GI.x(point), GI.y(point)
        bytes += Base.write(io, x)
        bytes += Base.write(io, y)
    end
    # write the other z/m parts if they exist
    b, zrange, mrange = _write_others(io, geom; kw...)
    bytes += b

    return bytes, mbr, zrange, mrange
end
function _write(io::IO, ::GI.PointTrait, point;
    hasz=GI.is3d(point), hasm=GI.ismeasured(point)
)
    bytes = Int64(0)
    x, y = Float64(GI.x(point)), Float64(GI.y(point))
    mbr = Rect(x, y, x, y)
    bytes += Base.write(io, x, y)
    if hasz
        z = Float64(GI.z(point))
        bytes += Base.write(io, z)
        zrange = Interval(z, z)
    else
        zrange = Interval(0.0, 0.0)
    end
    if hasm
        m = Float64(GI.m(point))
        bytes +=  Base.write(io, m)
        mrange = Interval(m, m)
    else
        mrange = Interval(0.0, 0.0)
    end

    return bytes, mbr, zrange, mrange
end

function _calc_mbr(geom)
    low_x = low_y = Inf
    high_x = high_y = -Inf
    for point in GI.getpoint(geom)
        x, y = GI.x(point), GI.y(point)
        low_x = min(low_x, x)
        high_x = max(high_x, x)
        low_y = min(low_y, y)
        high_y = max(high_y, y)
    end
    return Rect(low_x, low_y, high_x, high_y)
end

# z and m values are written separately if they exist
function _write_others(io, geom;
    hasz=GI.is3d(geom), hasm=GI.ismeasured(geom)
)
    bytes = 0
    # TODO what to do when hasm == false but hasz == true
    if hasz
        b, zrange = _write_others(GI.z, io, geom)
        bytes += b
    else
        zrange = Interval(0.0, 0.0)
    end

    if hasm
        b, mrange = _write_others(GI.m, io, geom)
        bytes += b
    else
        mrange = Interval(0.0, 0.0)
    end
    return bytes, zrange, mrange
end
function _write_others(f, io, geom)
    low = Inf
    high = -Inf
    for point in GI.getpoint(geom)
        m = f(point)
        low = min(low, m)
        high = max(high, m)
    end
    range = Interval(low, high)
    bytes = Base.write(io, range)
    for point in GI.getpoint(geom)
        m = f(point)
        bytes += Base.write(io, m)
    end
    return bytes, range
end

# Internal trait for shapes that track `parts` data
_nparts(trait, geom) = nothing
_nparts(trait::Union{GI.MultiPolygonTrait,GI.PolygonTrait}, geom) = Int32(GI.nring(geom))
_nparts(trait::GI.MultiLineStringTrait, geom) = Int32(GI.nlinestring(geom))

_get_parts(trait::Union{GI.MultiPolygonTrait,GI.PolygonTrait}, geom) = GI.getring(trait, geom)
_get_parts(trait, geom) = GI.getgeom(trait, geom)
