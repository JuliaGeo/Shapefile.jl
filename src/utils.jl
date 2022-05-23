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

# Most objects have similar structure, so we share conversion internals
function _convert(pointmode::Type{<:Point}, geom)
    n = GI.npoint(geom)
    points = _pointvec(n)
    for (i, point) in enumerate(GI.getpoint(geom))
        points[i] = Point(GI.x(point), GI.y(point))
    end
    MBR = _getbounds(points)
    return MBR, points
end
function _convert(::Type{<:PointM}, geom)
    hasm = GI.ismeasured(first(GI.getpoint(geom)))
    n = GI.npoint(geom)
    points = _pointvec(n)
    measures = _floatvec(n)
    for (i, point) in enumerate(GI.getpoint(geom))
        points[i] = Point(GI.x(point), GI.y(point))
        measures[i] = hasm ? GI.m(point) : 0.0
    end
    mrange = Interval(extrema(measures)...)
    MBR = _getbounds(points)
    return MBR, points, mrange, measures
end
function _convert(::Type{<:PointZ}, geom)
    hasz = GI.is3d(first(GI.getpoint(geom))) 
    hasm = GI.ismeasured(first(GI.getpoint(geom)))
    n = GI.npoint(geom)
    points = _pointvec(n)
    zvalues = _floatvec(n)
    measures = _floatvec(n)
    for (i, point) in enumerate(GI.getpoint(geom))
        points[i] = Point(GI.x(point), GI.y(point))
        zvalues[i] = hasz ? GI.z(point) : 0.0
        measures[i] = hasm ? GI.m(point) : 0.0
    end
    mrange = Interval(extrema(measures)...)
    zrange = Interval(extrema(zvalues)...)
    MBR = _getbounds(points)
    return MBR, points, zrange, zvalues, mrange, measures
end

# _convert with additional parts field
function _convertparts(T, geom) 
    MBR, args... = _convert(T, geom)
    parts = _getparts(geom)
    return (MBR, parts, args...)
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
