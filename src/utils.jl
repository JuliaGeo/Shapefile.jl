_partvec(n) = Vector{Int32}(undef, n)
_pointvec(n) = Vector{Point}(undef, n)
_floatvec(n) = Vector{Float64}(undef, n)

function _readparts(io, n)
    points = _partvec(n)
    read!(io, points)
    return points
end

function _readpoints(io, n)
    points = _pointvec(n)
    read!(io, points)
    return points
end

# ESRI reserves values strictly below -10^38 for measures with no data.
const M_NODATA = -1.0e39
_isnodata(m) = m < -1.0e38
_nodata_mrange() = Interval(M_NODATA, M_NODATA)

# Use the record boundary, not EOF: another shape may follow an omitted M block.
function _hasm(io, bytes, record_end)
    isnothing(record_end) && return !eof(io)
    remaining = record_end - position(io)
    remaining == 0 && return false
    remaining == bytes || throw(ArgumentError("Invalid measure block: expected $bytes bytes or no measures, found $remaining bytes"))
    return true
end

function _readm(io, n, record_end=nothing)
    if _hasm(io, 16 + 8 * Int(n), record_end)
        return _readfloats(io, n)
    end
    return _nodata_mrange(), fill(M_NODATA, n)
end
_readz(io, n) = _readfloats(io, n)
function _readfloats(io, n)
    interval = read(io, Interval)
    values = _floatvec(n)
    read!(io, values)
    return interval, values
end

_getparts(geom) = _getparts(GI.geomtrait(geom), geom)
# Special-case multi polygons because we only store the rings
function _getparts(::GI.MultiPolygonTrait, geom)
    parts = _partvec(GI.nring(geom))
    n = 0
    for (i, ring) in enumerate(GI.getring(geom))
        parts[i] = n
        n += GI.npoint(ring)
    end
    return parts
end
function _getparts(::GI.AbstractGeometryTrait, geom)
    parts = _partvec(GI.ngeom(geom))
    n = 0
    for (i, g) in enumerate(GI.getgeom(geom))
        parts[i] = n
        n += GI.npoint(g)
    end
    return parts
end

function _getbounds(points::Vector{Point})
    xrange = extrema(GI.x(p) for p in points)
    yrange = extrema(GI.y(p) for p in points)
    return Rect(xrange[1], yrange[1], xrange[2], yrange[2])
end


function _shape_paths(path)
    stempath, ext = splitext(path)
    if lowercase(ext) == ".shp"
        shp = path
    elseif ext == ""
        shp = string(stempath, ".shp")
    else
        throw(ArgumentError("Provide the shapefile with either `.shp` or no extension.\nFound `$ext`."))
    end

    shx = string(stempath, ".shx")
    dbf = string(stempath, ".dbf")
    prj = string(stempath, ".prj")

    return (; shp, shx, dbf, prj)
end
