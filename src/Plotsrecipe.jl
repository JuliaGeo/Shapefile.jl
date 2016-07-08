import RecipesBase

using RecipesBase
function shapefile_coords(poly::Shapefile.ESRIShape)
    start_indices = poly.parts+1
    end_indices = vcat(poly.parts[2:end], length(poly.points))
    x, y = zeros(0), zeros(0)
    for (si,ei) in zip(start_indices, end_indices)
        push!(x, NaN)
        push!(y, NaN)
        for pt in poly.points[si:ei]
            push!(x, pt.x)
            push!(y, pt.y)
        end
    end
    x, y
end

function shapefile_coords{T<:Shapefile.ESRIShape}(polys::AbstractVector{T})
    x, y = zeros(0), zeros(0)
    for poly in polys
        xpart, ypart = shapefile_coords(poly)
        append!(x, xpart)
        append!(y, ypart)
    end
    x, y
end

function shapefile_coords{T<:Shapefile.ESRIShape}(polys::AbstractMatrix{T})
    x, y = [], []
    for c in 1:size(polys,2)
        xy = shapefile_coords(vec(polys[:,c]))
        push!(x, xy[1])
        push!(y, xy[2])
    end
end

@recipe f(poly::Shapefile.ESRIShape) = (seriestype --> :shape; shapefile_coords(poly))
@recipe f{T<:Shapefile.ESRIShape}(polys::AbstractVector{T}) = (seriestype --> :shape; shapefile_coords(polys))
@recipe f{T<:Shapefile.ESRIShape}(polys::AbstractMatrix{T}) = (seriestype --> :shape; shapefile_coords(polys))
@recipe f{T<:Shapefile.Handle}(::Type{T}, handle::T) = handle.shapes'
