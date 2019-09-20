GeoInterface.coordinates(obj::Point) = Float64[obj.x, obj.y]
GeoInterface.coordinates(obj::PointM) = Float64[obj.x, obj.y]
GeoInterface.coordinates(obj::PointZ) = Float64[obj.x, obj.y, obj.z]

GeoInterface.coordinates(obj::MultiPoint) =
    Vector{Float64}[GeoInterface.coordinates(p) for p in obj.points]
GeoInterface.coordinates(obj::MultiPointM) =
    Vector{Float64}[GeoInterface.coordinates(p) for p in obj.points]
GeoInterface.coordinates(obj::MultiPointZ) =
    Vector{Float64}[GeoInterface.coordinates(p) for p in obj.points]

function GeoInterface.coordinates(obj::Polyline)
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[nparts] <= npoints
    push!(obj.parts, npoints)
    coords = Vector{Vector{Float64}}[Vector{Float64}[GeoInterface.coordinates(obj.points[j+1]) for j = obj.parts[i]:(obj.parts[i+1]-1)] for i = 1:nparts]
    pop!(obj.parts)
    coords
end

function GeoInterface.coordinates(obj::PolylineM)
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[nparts] <= npoints
    push!(obj.parts, npoints)
    coords = Vector{Vector{Float64}}[Vector{Float64}[GeoInterface.coordinates(obj.points[j+1]) for j = obj.parts[i]:(obj.parts[i+1]-1)] for i = 1:nparts]
    pop!(obj.parts)
    coords
end

function GeoInterface.coordinates(obj::PolylineZ)
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[nparts] <= npoints
    push!(obj.parts, npoints)
    coords = Vector{Vector{Float64}}[Vector{Float64}[GeoInterface.coordinates(obj.points[j+1]) for j = obj.parts[i]:(obj.parts[i+1]-1)] for i = 1:nparts]
    pop!(obj.parts)
    coords
end

# Only supports 2D geometries for now
# pt is [x,y] and ring is [[x,y], [x,y],..]
# ported from https://github.com/Turfjs/turf/blob/3d0efd96d59878f82c6d6baf8ed75695e0b6dbc0/packages/turf-inside/index.js#L76-L91
function inring(pt::Vector{Float64}, ring::Vector{Vector{Float64}})
    intersect(i::Vector{Float64}, j::Vector{Float64}) =
        (i[2] >= pt[2]) != (j[2] >= pt[2]) && (pt[1] <= (j[1] - i[1]) *
                                                        (pt[2] - i[2]) /
                                                        (j[2] - i[2]) + i[1])
    isinside = intersect(ring[1], ring[end])
    for k = 2:length(ring)
        isinside = intersect(ring[k], ring[k-1]) ? !isinside : isinside
    end
    isinside
end

# ported from https://github.com/Esri/terraformer-arcgis-parser/blob/master/terraformer-arcgis-parser.js#L168-L253
function GeoInterface.coordinates(obj::Polygon)
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[end] <= npoints
    coords = Vector{Vector{Vector{Float64}}}[]
    holes = Vector{Vector{Vector{Float64}}}()
    push!(obj.parts, npoints)
    for i = 1:nparts
        ringlength = obj.parts[i+1] - obj.parts[i]
        ringlength < 4 && continue
        test = 0.0
        ring = Vector{Vector{Float64}}()
        for j = (obj.parts[i]+1):(obj.parts[i+1]-1)
            prev = obj.points[j]
            cur = obj.points[j+1]
            test += (cur.x - prev.x) * (cur.y + prev.y)
            push!(ring, GeoInterface.coordinates(prev))
        end
        push!(ring, GeoInterface.coordinates(obj.points[obj.parts[i+1]]))
        @assert length(ring) == ringlength
        if test > 0 # clockwise
            push!(coords, Vector{Vector{Float64}}[ring]) # create new polygon
        else # anti-clockwise
            push!(holes, ring)
        end
    end
    pop!(obj.parts)
    nrings = length(coords)
    for hole in holes
        for i = 1:nrings
            if inring(hole[1], coords[i][1])
                push!(coords[i], hole)
                break
            end
        end
        push!(coords, Vector{Vector{Float64}}[hole]) # hole is not inside any ring; make it a polygon
    end
    coords
end

# copied from GeoInterface.coordinates{T}(obj::Polygon{T}) to match signature here
function GeoInterface.coordinates(obj::PolygonM)
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[end] <= npoints
    coords = Vector{Vector{Vector{Float64}}}[]
    holes = Vector{Vector{Vector{Float64}}}()
    push!(obj.parts, npoints)
    for i = 1:nparts
        ringlength = obj.parts[i+1] - obj.parts[i]
        ringlength < 4 && continue
        test = 0.0
        ring = Vector{Vector{Float64}}()
        for j = (obj.parts[i]+1):(obj.parts[i+1]-1)
            prev = obj.points[j]
            cur = obj.points[j+1]
            test += (cur.x - prev.x) * (cur.y + prev.y)
            push!(ring, GeoInterface.coordinates(prev))
        end
        push!(ring, GeoInterface.coordinates(obj.points[obj.parts[i+1]]))
        @assert length(ring) == ringlength
        if test > 0 # clockwise
            push!(coords, Vector{Vector{Float64}}[ring]) # create new polygon
        else # anti-clockwise
            push!(holes, ring)
        end
    end
    pop!(obj.parts)
    nrings = length(coords)
    for hole in holes
        for i = 1:nrings
            if inring(hole[1], coords[i][1])
                push!(coords[i], hole)
                break
            end
        end
        push!(coords, Vector{Vector{Float64}}[hole]) # hole is not inside any ring; make it a polygon
    end
    coords
end

# copied from GeoInterface.coordinates{T}(obj::Polygon{T}) to match signature here
function GeoInterface.coordinates(obj::PolygonZ)
    npoints = length(obj.points)
    nparts = length(obj.parts)
    @assert obj.parts[end] <= npoints
    coords = Vector{Vector{Vector{Float64}}}[]
    holes = Vector{Vector{Vector{Float64}}}()
    push!(obj.parts, npoints)
    for i = 1:nparts
        ringlength = obj.parts[i+1] - obj.parts[i]
        ringlength < 4 && continue
        test = 0.0
        ring = Vector{Vector{Float64}}()
        for j = (obj.parts[i]+1):(obj.parts[i+1]-1)
            prev = obj.points[j]
            cur = obj.points[j+1]
            test += (cur.x - prev.x) * (cur.y + prev.y)
            push!(ring, GeoInterface.coordinates(prev))
        end
        push!(ring, GeoInterface.coordinates(obj.points[obj.parts[i+1]]))
        @assert length(ring) == ringlength
        if test > 0 # clockwise
            push!(coords, Vector{Vector{Float64}}[ring]) # create new polygon
        else # anti-clockwise
            push!(holes, ring)
        end
    end
    pop!(obj.parts)
    nrings = length(coords)
    for hole in holes
        for i = 1:nrings
            if inring(hole[1], coords[i][1])
                push!(coords[i], hole)
                break
            end
        end
        push!(coords, Vector{Vector{Float64}}[hole]) # hole is not inside any ring; make it a polygon
    end
    coords
end
