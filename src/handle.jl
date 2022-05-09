"""
    Handle

    Handle(path::AbstractString, [indexpath::AbstractString])

Load a shapefile into GeoInterface compatible objects. This can be plotted
with Plots.jl `plot`.

The Vector of shape object can be accessed with `shapes(handle)`.

`Handle` may have a known bounding box, which can be retrieved with `GeoInterface.bbox`.
"""
mutable struct Handle{T<:Union{<:AbstractShape,Missing}}
    code::Int32
    length::Int32
    version::Int32
    shapeType::Int32
    MBR::Rect
    zrange::Interval
    mrange::Interval
    shapes::Vector{T}
    crs::Union{Nothing,GeoFormatTypes.ESRIWellKnownText}
end
function Handle(path::AbstractString, index=nothing)
    open(path) do io
        read(io, Handle, index; path = path)
    end
end
function Handle(path::AbstractString, indexpath::AbstractString)
    index = open(indexpath) do io
        read(io, IndexHandle)
    end
    Handle(path, index)
end

shapes(h::Handle) = h.shapes

GeoInterface.crs(h::Handle) = h.crs

Base.length(shp::Handle) = length(shapes(shp))

function Base.read(io::IO, ::Type{Handle}, index = nothing; path = nothing)
    code = bswap(read(io, Int32))
    read!(io, Vector{Int32}(undef, 5))
    fileSize = bswap(read(io, Int32))
    version = read(io, Int32)
    shapeType = read(io, Int32)
    MBR = read(io, Rect)
    zmin = read(io, Float64)
    zmax = read(io, Float64)
    mmin = read(io, Float64)
    mmax = read(io, Float64)
    jltype = SHAPETYPE[shapeType]
    shapes = Vector{Union{jltype,Missing}}(undef, 0)
    crs = nothing
    if path !== nothing
        prjfile = string(splitext(path)[1], ".prj")
        if isfile(prjfile) 
            try
                crs = GeoFormatTypes.ESRIWellKnownText(read(open(prjfile), String))
            catch
                @warn "Projection file $prjfile appears to be corrupted. `nothing` used for `crs`"
            end
        end
    end
    num = Int32(0)
    while (!eof(io))
        seeknext(io, num, index)
        num = bswap(read(io, Int32))
        rlength = bswap(read(io, Int32))
        shapeType = read(io, Int32)
        if shapeType === Int32(0)
            push!(shapes, missing)
        else
            push!(shapes, read(io, jltype))
        end
    end
    return Handle(
        code,
        fileSize,
        version,
        shapeType,
        MBR,
        Interval(zmin, zmax),
        Interval(mmin, mmax),
        shapes,
        crs,
    )
end

function seeknext(io, num, index::IndexHandle)
    seek(io, index.indices[num+1].offset * 2)
end
seeknext(io, num, ::Nothing) = nothing
