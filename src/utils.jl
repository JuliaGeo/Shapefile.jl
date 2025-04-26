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

_readm(io, n) = _readfloats(io, n)
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
