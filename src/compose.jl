#Provide utility functions for interoperability with Compose.jl
#Define conversions from Shapefile.jl shape primitives to their Compose.jl counterparts

#Convert Shapefile rectangle to Compose rectangle
import Compose: rectangle
rectangle{T<:Real}(R::Shapefile.Rect{T}) = rectangle(R.left,R.top,R.right-R.left,R.bottom-R.top)

#Compose polygons cannot be disjoint but Shapefile.Polygons can
#Need to convert Shapefile.Polygon to list of Compose polygons
function convert(::Type{Vector{Compose.Form{Compose.PolygonPrimitive}}},
        shape::Shapefile.Polygon)
    points = {}
    polygons={}
    currentpart=2
    for (i,p) in enumerate(shape.points)
        push!(points, p)
        if i==length(shape.points) || (currentpart≤length(shape.parts) && i==shape.parts[currentpart])
            push!(polygons, polygon([(p.x,p.y) for p in points]))
            currentpart += 1
            points = {}
        end
    end
    polygons
end

polygons(shape::Shapefile.Polygon) = convert(Vector{Compose.Form{Compose.PolygonPrimitive}},
    shape)
