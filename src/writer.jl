# Reverse lookup for Shapetype to Code
write(path::AbstractString, h::Handle) = write(path, h.shapes)
function write(path::AbstractString, obj; force=false)
    paths = _shape_paths(path)
    if isfile(paths.shp)
        if force
            rm(paths.shp)
        else
            throw(ArgumentError("File already exists at `$(paths.shp)`. Use `force=true` to write anyway."))
        end
    end
    if Tables.istable(obj)
        geomcol = GI.geometrycolumn(obj)
        geoms = Tables.getcolumn(obj, geomcol)
        # DBFTables.Table(obj) # TODO remove geom column
        # DBFTables.write # TODO DBF write function
    else
        geoms = obj
    end

    # Write .shp file
    io = open(paths.shp, "a+")

    shx_indices = IndexRecord[]
    bytes = 0
    content_size = 0
    first_geom = true
    local mbr, zrange, mrange

    # Write an emtpy header 
    # We go back later and write it properly later, so we don't have to precalculate everything.
    dummy_header = Header(;
        filesize=0, 
        shapecode=SHAPECODE[Missing],
        mbr=Rect(0.0, 0.0, 0.0, 0.0),
        zrange=Interval(0.0, 0.0),
        mrange=Interval(0.0, 0.0),
    )
    bytes += Base.write(io, dummy_header)
    header_bytes = bytes

    # Since all the headers has some sort of content length information before the data block.
    # The code here will write out the data into a IOBuffer first to get the content length.
    # Finally it write the length information and then unload the IOBuffer data into the main block.
    
    # Detect the shape type code from the first available geometry
    # There can only be one shape type in the file.
    if iterate(skipmissing(geoms)) == nothing
        trait = Missing
        hasz = hasm = false
        shapecode = 0 
        mbr = Rect(0.0, 0.0, 0.0, 0.0)
        zrange = Interval(0.0, 0.0)
        mrange = Interval(0.0, 0.0)
    else
        geom1 = first(skipmissing(geoms))
        GI.isgeometry(geom1) || error("$(typeof(geom1)) is not a geometry")
        trait = GI.geomtrait(geom1)
        if trait isa GI.GeometryCollectionTrait 
            @warn "Geometry Collections or MultiPatch cannot be written using Shapefile.jl"
            return nothing
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

    # @assert bytes == io.size "The hardcoded accumulation of bytes $bytes should match how much bytes it has written into the buffer $(io.size)"

    # Write the main block of data into the rest of the shape file
    for (num, geom) in enumerate(geoms)
        (trait === Missing || trait === GI.geomtrait(geom)) || throw(ArgumentError("Shapefiles can only contain geometries of the same type"))
        # One-based record number; Increment from 0, and increment after record.
        rec_bytes = Base.write(io, bswap(Int32(num)))
        calc_recbytes = sizeof(Int32) # shape code

        if ismissing(geom)
            rec_bytes += Base.write(io, bswap(Int32(calc_recbytes)))
            rec_bytes += Base.write(io, SHAPECODE[Missing])
            bytes += rec_bytes
            content_size += rec_bytes

            # Indices for .shx file
            offset = bytes ÷ 2
            push!(shx_indices, IndexRecord(offset, rec_bytes))
            continue
        end

        if trait isa GI.PointTrait 
            calc_recbytes += sizeof(Float64) * 2 # point values
            if hasz
                calc_recbytes += sizeof(Float64) # z values
            end
            if hasm
                calc_recbytes += sizeof(Float64) # measures
            end
        else
            # box = read(io, Rect)
            # numpoints = read(io, Int32)
            # points = _readpoints(io, numpoints)

            n = GI.npoint(geom)
            calc_recbytes += sizeof(Rect) # Rect
            calc_recbytes += sizeof(Int32) # num points
            calc_recbytes += sizeof(Float64) * n * 2 # point values
            if hasz
                calc_recbytes += sizeof(Interval) # z interval
                calc_recbytes += sizeof(Float64) * n # z values
            end
            if hasm
                calc_recbytes += sizeof(Interval) # m interval
                calc_recbytes += sizeof(Float64) * n # measures
            end
            numparts = _nparts(trait, geom) 
            if !isnothing(numparts)
                calc_recbytes += sizeof(Int32) # num parts
                calc_recbytes += sizeof(Int32) * numparts # parts offsets
            end
        end

        # Writing
        #
        # length
        # measured in 16 bit increments, so divid by 2
        rec_bytes += Base.write(io, bswap(Int32(calc_recbytes ÷ 2)))
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

        # Record Header
        # 32-bits (4 bytes) Record Number + 32-bits (4 bytes) Content length = 8 bytes
        bytes += rec_bytes
        content_size += rec_bytes

        # Indices for .shx file
        offset = bytes ÷ 2
        push!(shx_indices, IndexRecord(offset, rec_bytes)) # TODO div by 2??
    end

    @assert bytes == content_size + header_bytes "The hardcoded accumulation of bytes $(content_size + header_bytes) should match how much bytes it has written into the buffer $bytes"

    # Finally write the correct header at the start of the file
    header = Header(; filesize=bytes ÷ 2, shapecode, mbr, zrange, mrange)
    seek(io, 0)
    Base.write(io, header)
    
    # Write .shx file
    index_handle = IndexHandle(header, shx_indices)
    Base.write(paths.shx, index_handle)
    close(io)

    return bytes
end

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
    bytes += _write_xy(io, geom)
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

function _write_xy(io, geom)
    bytes = 0
    for point in GI.getpoint(geom)
        x, y = GI.x(point), GI.y(point)
        bytes += Base.write(io, x)
        bytes += Base.write(io, y)
    end
    return bytes
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
