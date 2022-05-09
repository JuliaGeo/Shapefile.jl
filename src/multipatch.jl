"""
    MultiPatch

Stores a collection of patch representing the boundary of a 3d object.

# Fields
- `points`: a `Vector` of [`Point`](@ref) represents a one or multiple spatial objects. 
- `parts`: a `Vector` of `Int32` indicating the object each point belongs to.
- `parttypes`: a `Vector` of `Int32` indicating the type of object each point belongs to.
- `zvalues`: a `Vector` of `Float64` indicating absolute or relative heights.
- `MBR`: `nothing` or the known bounding box. Can be retrieved with `GeoInterface.bbox`.
"""
struct MultiPatch <: AbstractShape
    MBR::Rect
    parts::Vector{Int32}
    parttypes::Vector{Int32}
    points::Vector{Point}
    zrange::Interval
    zvalues::Vector{Float64}
    # measures::Vector{Float64}  # (optional)
end

GeoInterface.geomtype(::MultiPatch) = GeoInterface.MultiPolygonTrait()
GeoInterface.ncoord(::MultiPatch) = 3

function Base.read(io::IO, ::Type{MultiPatch})
    box = read(io, Rect)
    numparts = read(io, Int32)
    numpoints = read(io, Int32)
    parts = Vector{Int32}(undef, numparts)
    read!(io, parts)
    parttypes = Vector{Int32}(undef, numparts)
    read!(io, parttypes)
    points = Vector{Point}(undef, numpoints)
    read!(io, points)
    zrange = read(io, Interval)
    zvalues = Vector{Float64}(undef, numpoints)
    read!(io, zvalues)
    # mrange = Vector{Float64}(2)
    # read!(io, mrange)
    # measures = Vector{Float64}(numpoints)
    # read!(io, measures)
    MultiPatch(box, parts, parttypes, points, zrange, zvalues) #,measures)
end
