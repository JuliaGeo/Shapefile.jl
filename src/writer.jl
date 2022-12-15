
"""
    write(path::AbstractString, handle::Shapefile.Handle)
    write(path::AbstractString, geoms)

Write geometries to file. `geoms` can be a table or any iterable of GeoInterface.jl
combatible geometry objects, with `missing` values allowed.

Note: As DBFTables.jl does not yet write, we can't write Table or FeatureCollection
data besides geometries. Only .shp and .shx files are written currently.
"""
# write(path::AbstractString, h::Handle) = write(path, h.shapes)
function write(path::AbstractString, obj; force=false)
    paths = _shape_paths(path)

    # File existance check
    if isfile(paths.shp)
        if force
            rm(paths.shp)
        else
            throw(ArgumentError("File already superexists at `$(paths.shp)`. Use `force=true` to write anyway."))
        end
    end

    # Handle tabular data
    if Tables.istable(obj)
        geomcol = first(GI.geometrycolumns(obj))
        geoms = Tables.getcolumn(obj, geomcol)
        @warn "DBFTables.jl does not yet `write`, so only .shp, .shx, and .prj files can be written."
        # DBFTables.Table(obj) # TODO remove geom column
        # DBFTables.write # TODO DBF write function
    elseif GI.geomtrait(obj) isa GI.AbstractGeometryCollectionTrait
        geoms = (GI.getgeom(obj, i) for i in 1:GI.ngeom(obj))
    else
        geoms = obj
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
        (trait === Missing || trait === GI.geomtrait(geom)) || throw(ArgumentError("Shapefiles can only contain geometries of the same type"))

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

    # Write .prj file
    crs = try
        GI.crs(obj)
    catch
        nothing
    end
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
