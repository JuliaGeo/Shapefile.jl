function parts_poly(points::Vector{Point}, parts::Vector{Int32})
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
    return exterior, interior_pts
end