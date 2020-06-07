function parts_polygon(points::Vector{Point}, parts::Vector{Int32})
    exterior_pts = Vector{GB.Point{2, Float64}}[]
    interior_pts = Vector{GB.Point{2, Float64}}[]
    parts .+= 1
    for i in 1:length(parts)
        if i == 1 && length(parts) != 1
            exterior_pts = collect(points[x] for x in parts[i]:parts[i+1]-1)
        elseif length(parts) == 1
            exterior_pts = points
        elseif i < length(parts) && i > 1 
            push!(interior_pts, collect(points[x] for x  in parts[i]:parts[i+1]-1))
        else
            push!(interior_pts, collect(points[x] for x  in parts[i]:length(points)))
        end
    end
    exterior = GB.LineString(exterior_pts)
    if length(interior_pts) !=0
        interiors = collect(GB.LineString(pts) for pts in interior_pts)
        return GB.Polygon(exterior, interiors)
    else
        return GB.Polygon(exterior)
    end
end

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
