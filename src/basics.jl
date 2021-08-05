using PolygonOps

function parts_polygon(points::Vector{Point}, parts::Vector{Int32})
    rings = Vector{GB.Point{2, Float64}}[]
    parts .+= 1
    push!(parts, length(points)+1)
    # - split points into parts (rings)
    # - determine if rings are exterior or interior (holes)
    for i in 1:(length(parts)-1)
        ring = collect(points[x] for x in parts[i]:parts[i+1]-1)
        push!(rings, ring)
    end

    polygon_from_rings(rings)
end

function polygon_from_rings(rings)
    # Split rings into exterior rings and holes
    ext_rings = filter(!hole, rings)
    int_rings = filter(hole, rings)
        
    # For each hole find the corresponding exterior ring
    matched_ext_inds = find_exterior_ring.(int_rings, Ref(ext_rings))
    
    # Dealing with orphaned holes (== reversed exteriors)
    orphaned_hole_inds = isnothing.(matched_ext_inds)
    
    if length(orphaned_hole_inds) > 0
        @warn "Misspecified multipolygon"
        ext_rings = [ext_rings; int_rings[orphaned_hole_inds]]
        int_rings = int_rings[.! orphaned_hole_inds]

        matched_ext_inds = find_exterior_ring.(int_rings, Ref(ext_rings))
    end

    # Combine exteriors with corresponding holes into polygons
    polygons = map(enumerate(ext_rings)) do (i, ext)
        hole_inds = findall(matched_ext_inds .== i)
        if length(hole_inds) > 0
            GB.Polygon(ext, int_rings[hole_inds])
        else
            GB.Polygon(ext)
        end
    end

    # Combine polygons into a MultiPolygon
    GB.MultiPolygon(polygons)

end

function find_exterior_ring(interior_ring, exterior_rings)
    ext_inds = findall(iscontained.(Ref(interior_ring), exterior_rings))
        
    if isempty(ext_inds)
        nothing
    elseif length(ext_inds) == 1
        only(ext_inds)
    else
        ext_inds[find_smallest_ring(exterior_rings[ext_inds])]
    end
end

"""
Find smallest ring of a collection rings {x₁, x₂, ..., xₙ} for which
xᵢ ⊂ xⱼ or xᵢ ⊃ xⱼ for all i,j
"""
function find_smallest_ring(rings)
    @assert length(rings) > 0
    # rings need to be either ⊂ or ⊃ or both
    sortperm(rings, lt = iscontained)[1]
end

"Checks containedment for non-overlapping polygons"
function iscontained(haystack, needle)
    out = nothing
    for int_point in haystack
        res = inpolygon(int_point, needle)
        if res == -1
            continue
        elseif res == 1
            return true
        elseif res == 0
            return false
        end
    end
    @error "all points of haystack are *on* needle"
end

using ShiftedArrays
# check if non-convex polygon is clockwise: 
# https://stackoverflow.com/a/1165943/4984167
function f(edge)
    x1, y1 = edge[1]
    x2, y2 = edge[2]
    (x2 - x1) * (y2 + y1)
    #y1 * x2 - y2 * x1 # used in linked js code
end
edges(pts) = zip(pts, ShiftedArrays.circshift(pts, -1)) # ShiftedArrays.circshift is lazy
clockwise(pts) = sum(f, edges(pts)) >= 0
hole(pts) = !clockwise(pts)

function parts_polyline(points::Vector{Point}, parts::Vector{Int32})
    linestrings = GB.LineString{2,Float64,GB.Point{2,Float64}}[]
    parts .+= 1
    for i in 1:length(parts)
        if length(parts) != 1 && i < length(parts)
            pts = collect(points[x] for x in parts[i]:parts[i+1]-1)
            push!(linestrings, GB.LineString(pts))
        elseif length(parts) == 1 && parts[1]==1
            push!(linestrings, GB.LineString(points))
        else
            pts = collect(points[x] for x in parts[i]:length(points))
            push!(linestrings, GB.LineString(pts))
        end
    end
    return GB.MultiLineString(linestrings) 
end
