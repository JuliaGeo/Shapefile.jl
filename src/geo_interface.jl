GeoInterface.coordinates(obj::Point{T}) where {T <: Real} = T[obj.x, obj.y]
GeoInterface.coordinates(obj::PointM{T}) where {T <: Real} = T[obj.x, obj.y]
GeoInterface.coordinates(obj::PointZ{T}) where {T <: Real} = T[obj.x, obj.y, obj.z]

GeoInterface.coordinates(obj::MultiPoint{T}) where {T <: Real} =
    Vector{T}[GeoInterface.coordinates(p) for p in obj.points]
GeoInterface.coordinates(obj::MultiPointM{T,M}) where {T,M} =
    Vector{T}[GeoInterface.coordinates(p) for p in obj.points]
GeoInterface.coordinates(obj::MultiPointZ{T,M}) where {T,M} =
    Vector{T}[GeoInterface.coordinates(p) for p in obj.points]

function GeoInterface.coordinates(obj::Polyline{T}) where T
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[nparts] <= npoints
    push!(obj.parts, npoints)
    coords = Vector{Vector{T}}[
        Vector{T}[
            GeoInterface.coordinates(obj.points[j+1])
            for j in obj.parts[i]:(obj.parts[i+1]-1)
        ]
        for i in 1:nparts
    ]
    pop!(obj.parts)
    coords
end

function GeoInterface.coordinates(obj::PolylineM{T,M}) where {T, M}
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[nparts] <= npoints
    push!(obj.parts, npoints)
    coords = Vector{Vector{T}}[
        Vector{T}[
            GeoInterface.coordinates(obj.points[j+1])
            for j in obj.parts[i]:(obj.parts[i+1]-1)
        ]
        for i in 1:nparts
    ]
    pop!(obj.parts)
    coords
end

function GeoInterface.coordinates(obj::PolylineZ{T,M}) where {T, M}
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[nparts] <= npoints
    push!(obj.parts, npoints)
    coords = Vector{Vector{T}}[
        Vector{T}[
            GeoInterface.coordinates(obj.points[j+1])
            for j in obj.parts[i]:(obj.parts[i+1]-1)
        ]
        for i in 1:nparts
    ]
    pop!(obj.parts)
    coords
end

# Only supports 2D geometries for now
# pt is [x,y] and ring is [[x,y], [x,y],..]
# ported from https://github.com/Turfjs/turf/blob/3d0efd96d59878f82c6d6baf8ed75695e0b6dbc0/packages/turf-inside/index.js#L76-L91
function inring(pt::Vector{T}, ring::Vector{Vector{T}}) where T
    intersect(i::Vector{T},j::Vector{T}) =
        (i[2] >= pt[2]) != (j[2] >= pt[2]) && (pt[1] <= (j[1] - i[1]) * (pt[2] - i[2]) / (j[2] - i[2]) + i[1])
    isinside = intersect(ring[1], ring[end])
    for k in 2:length(ring)
        isinside = intersect(ring[k], ring[k-1]) ? !isinside : isinside
    end
    isinside
end

# ported from https://github.com/Esri/terraformer-arcgis-parser/blob/master/terraformer-arcgis-parser.js#L168-L253
function GeoInterface.coordinates(obj::Polygon{T}) where T
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[end] <= npoints
    coords = Vector{Vector{Vector{T}}}[]
    holes = Vector{Vector{Vector{T}}}()
    push!(obj.parts, npoints)
        for i in 1:nparts
            ringlength = obj.parts[i+1] - obj.parts[i]
            ringlength < 4 && continue
            test = 0.0
            ring = Vector{Vector{T}}()
            for j in (obj.parts[i]+1):(obj.parts[i+1]-1)
                prev = obj.points[j]; cur = obj.points[j+1]
                test += (cur.x - prev.x) * (cur.y + prev.y)
                push!(ring, GeoInterface.coordinates(prev))
            end
            push!(ring, GeoInterface.coordinates(obj.points[obj.parts[i+1]]))
            @assert length(ring) == ringlength
            if test > 0 # clockwise
                push!(coords, Vector{Vector{T}}[ring]) # create new polygon
            else # anti-clockwise
                push!(holes, ring)
            end
        end
    pop!(obj.parts)
    nrings = length(coords)
    for hole in holes
        for i in 1:nrings
            if inring(hole[1], coords[i][1])
                push!(coords[i], hole)
                break
            end
        end
        push!(coords, Vector{Vector{T}}[hole]) # hole is not inside any ring; make it a polygon
    end
    coords
end

# copied from GeoInterface.coordinates{T}(obj::Polygon{T}) to match signature here
function GeoInterface.coordinates(obj::PolygonM{T,M}) where {T, M}
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[end] <= npoints
    coords = Vector{Vector{Vector{T}}}[]
    holes = Vector{Vector{Vector{T}}}()
    push!(obj.parts, npoints)
        for i in 1:nparts
            ringlength = obj.parts[i+1] - obj.parts[i]
            ringlength < 4 && continue
            test = 0.0
            ring = Vector{Vector{T}}()
            for j in (obj.parts[i]+1):(obj.parts[i+1]-1)
                prev = obj.points[j]; cur = obj.points[j+1]
                test += (cur.x - prev.x) * (cur.y + prev.y)
                push!(ring, GeoInterface.coordinates(prev))
            end
            push!(ring, GeoInterface.coordinates(obj.points[obj.parts[i+1]]))
            @assert length(ring) == ringlength
            if test > 0 # clockwise
                push!(coords, Vector{Vector{T}}[ring]) # create new polygon
            else # anti-clockwise
                push!(holes, ring)
            end
        end
    pop!(obj.parts)
    nrings = length(coords)
    for hole in holes
        for i in 1:nrings
            if inring(hole[1], coords[i][1])
                push!(coords[i], hole)
                break
            end
        end
        push!(coords, Vector{Vector{T}}[hole]) # hole is not inside any ring; make it a polygon
    end
    coords
end

# copied from GeoInterface.coordinates{T}(obj::Polygon{T}) to match signature here
function GeoInterface.coordinates(obj::PolygonZ{T,M}) where {T, M}
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[end] <= npoints
    coords = Vector{Vector{Vector{T}}}[]
    holes = Vector{Vector{Vector{T}}}()
    push!(obj.parts, npoints)
        for i in 1:nparts
            ringlength = obj.parts[i+1] - obj.parts[i]
            ringlength < 4 && continue
            test = 0.0
            ring = Vector{Vector{T}}()
            for j in (obj.parts[i]+1):(obj.parts[i+1]-1)
                prev = obj.points[j]; cur = obj.points[j+1]
                test += (cur.x - prev.x) * (cur.y + prev.y)
                push!(ring, GeoInterface.coordinates(prev))
            end
            push!(ring, GeoInterface.coordinates(obj.points[obj.parts[i+1]]))
            @assert length(ring) == ringlength
            if test > 0 # clockwise
                push!(coords, Vector{Vector{T}}[ring]) # create new polygon
            else # anti-clockwise
                push!(holes, ring)
            end
        end
    pop!(obj.parts)
    nrings = length(coords)
    for hole in holes
        for i in 1:nrings
            if inring(hole[1], coords[i][1])
                push!(coords[i], hole)
                break
            end
        end
        push!(coords, Vector{Vector{T}}[hole]) # hole is not inside any ring; make it a polygon
    end
    coords
end
