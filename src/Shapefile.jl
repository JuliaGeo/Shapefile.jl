__precompile__()

module Shapefile

    import GeoInterface
    import Base: read, show, +, /

    export Handle, RGBGradient, LogLinearRGBGradient, LinearRGBGradient

    type Rect{T}
        top::T
        left::T
        bottom::T
        right::T
    end

    type NullShape <: GeoInterface.AbstractGeometry
    end

    type Interval{T}
        left::T
        right::T
    end

    type Point{T} <: GeoInterface.AbstractPoint
        x::T
        y::T
    end

    +{T}(a::Point{T},b::Point{T}) = Point{T}(a.x+b.x,a.y+b.y)
    /{T}(a::Point{T},val::Real) = Point{T}(a.x/val,a.y/val)

    type PointM{T,M} <: GeoInterface.AbstractPoint
        x::T
        y::T
        m::M # measure
    end

    type PointZ{T,M} <: GeoInterface.AbstractPoint
        x::T
        y::T
        z::T
        m::M # measure
    end

    type Polyline{T} <: GeoInterface.AbstractMultiLineString
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
    end

    type PolylineM{T,M} <: GeoInterface.AbstractMultiLineString
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
        measures::Vector{M}
    end

    type PolylineZ{T,M} <: GeoInterface.AbstractMultiLineString
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
        zvalues::Vector{T}
        measures::Vector{M}
    end

    type Polygon{T} <: GeoInterface.AbstractMultiPolygon
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
    end

    show{T}(io::IO,p::Polygon{T}) = print(io,"Polygon(",length(p.points)," ",T," Points)")

    type PolygonM{T,M} <: GeoInterface.AbstractMultiPolygon
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
        measures::Vector{M}
    end

    type PolygonZ{T,M} <: GeoInterface.AbstractMultiPolygon
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
        zvalues::Vector{T}
        measures::Vector{M}
    end

    type MultiPoint{T} <: GeoInterface.AbstractMultiPoint
        MBR::Rect{T}
        points::Vector{Point{T}}
    end

    type MultiPointM{T,M} <: GeoInterface.AbstractMultiPoint
        MBR::Rect{T}
        points::Vector{Point{T}}
        measures::Vector{M}
    end

    type MultiPointZ{T,M} <: GeoInterface.AbstractMultiPoint
        MBR::Rect{T}
        points::Vector{Point{T}}
        zvalues::Vector{T}
        measures::Vector{M}
    end

    type MultiPatch{T,M} <: GeoInterface.AbstractGeometry
        MBR::Rect{T}
        parts::Vector{Int32}
        parttypes::Vector{Int32}
        points::Vector{Point{T}}
        zvalues::Vector{T}
        # measures::Vector{M} # (optional)
    end

    const SHAPETYPE = Dict{Int32, Any}(
        0  => NullShape,
        1  => Point{Float64},
        3  => Polyline{Float64},
        5  => Polygon{Float64},
        8  => MultiPoint{Float64},
        11 => PointZ{Float64,Float64},
        13 => PolylineZ{Float64,Float64},
        15 => PolygonZ{Float64,Float64},
        18 => MultiPointZ{Float64,Float64},
        21 => PointM{Float64,Float64},
        23 => PolylineM{Float64,Float64},
        25 => PolygonM{Float64,Float64},
        28 => MultiPointM{Float64,Float64},
        31 => MultiPatch{Float64,Float64}
    )

    type Handle{T <: GeoInterface.AbstractGeometry}
        code::Int32
        length::Int32
        version::Int32
        shapeType::Int32
        MBR::Rect{Float64}
        zrange::Interval{Float64}
        mrange::Interval{Float64}
        shapes::Vector{T}
    end

    function read{T}(io::IO,::Type{Rect{T}})
        minx = read(io,T)
        miny = read(io,T)
        maxx = read(io,T)
        maxy = read(io,T)
        Rect{T}(miny,minx,maxy,maxx)
    end

    read(io::IO,::Type{NullShape}) = NullShape()

    function read{T}(io::IO,::Type{Point{T}})
        x = read(io,T)
        y = read(io,T)
        Point{T}(x,y)
    end

    function read{T,M}(io::IO,::Type{PointM{T,M}})
        x = read(io,T)
        y = read(io,T)
        m = read(io,M)
        PointM{T,M}(x,y,m)
    end

    function read{T,M}(io::IO,::Type{PointZ{T,M}})
        x = read(io,T)
        y = read(io,T)
        z = read(io,T)
        m = read(io,M)
        PointZ{T,M}(x,y,z,m)
    end

    function read{T}(io::IO,::Type{Polyline{T}})
        box = read(io,Rect{T})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array{Int32}(numparts)
        read!(io, parts)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        Polyline{T}(box,parts,points)
    end

    function read{T,M}(io::IO,::Type{PolylineM{T,M}})
        box = read(io,Rect{T})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array{Int32}(numparts)
        read!(io, parts)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        mrange = Array{M}(2)
        read!(io, mrange)
        measures = Array{M}(numpoints)
        read!(io, measures)
        PolylineM{T,M}(box,parts,points,measures)
    end

    function read{T,M}(io::IO,::Type{PolylineZ{T,M}})
        box = read(io,Rect{T})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array{Int32}(numparts)
        read!(io, parts)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        zrange = Array{T}(2)
        read!(io, zrange)
        zvalues = Array{T}(numpoints)
        read!(io, zvalues)
        mrange = Array{M}(2)
        read!(io, mrange)
        measures = Array{M}(numpoints)
        read!(io, measures)
        PolylineZ{T,M}(box,parts,points,zvalues,measures)
    end

    function read{T}(io::IO,::Type{Polygon{T}})
        box = read(io,Rect{Float64})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array{Int32}(numparts)
        read!(io, parts)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        Polygon{T}(box,parts,points)
    end

    function read{T,M}(io::IO,::Type{PolygonM{T,M}})
        box = read(io,Rect{Float64})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array{Int32}(numparts)
        read!(io, parts)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        mrange = Array{M}(2)
        read!(io, mrange)
        measures = Array{M}(numpoints)
        read!(io, measures)
        PolygonM{T,M}(box,parts,points,measures)
    end

    function read{T,M}(io::IO,::Type{PolygonZ{T,M}})
        box = read(io,Rect{Float64})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array{Int32}(numparts)
        read!(io, parts)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        zrange = Array{T}(2)
        read!(io, zrange)
        zvalues = Array{T}(numpoints)
        read!(io, zvalues)
        mrange = Array{M}(2)
        read!(io, mrange)
        measures = Array{M}(numpoints)
        read!(io, measures)
        PolygonZ{T,M}(box,parts,points,zvalues,measures)
    end

    function read{T}(io::IO,::Type{MultiPoint{T}})
        box = read(io,Rect{Float64})
        numpoints = read(io,Int32)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        MultiPoint{T}(box,points)
    end

    function read{T,M}(io::IO,::Type{MultiPointM{T,M}})
        box = read(io,Rect{Float64})
        numpoints = read(io,Int32)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        mrange = Array{M}(2)
        read!(io, mrange)
        measures = Array{M}(numpoints)
        read!(io, measures)
        MultiPointM{T,M}(box,points,measures)
    end

    function read{T,M}(io::IO,::Type{MultiPointZ{T,M}})
        box = read(io,Rect{Float64})
        numpoints = read(io,Int32)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        zrange = Array{T}(2)
        read!(io, zrange)
        zvalues = Array{T}(numpoints)
        read!(io, zvalues)
        mrange = Array{M}(2)
        read!(io, mrange)
        measures = Array{M}(numpoints)
        read!(io, measures)
        MultiPointZ{T,M}(box,points,zvalues,measures)
    end

    function read{T,M}(io::IO,::Type{MultiPatch{T,M}})
        box = read(io,Rect{Float64})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array{Int32}(numparts)
        read!(io, parts)
        parttypes = Array{Int32}(numparts)
        read!(io, parttypes)
        points = Array{Point{T}}(numpoints)
        read!(io, points)
        zrange = Array{T}(2)
        read!(io, zrange)
        zvalues = Array{T}(numpoints)
        read!(io, zvalues)
        # mrange = Array{M}(2)
        # read!(io, mrange)
        # measures = Array{M}(numpoints)
        # read!(io, measures)
        MultiPatch{T,M}(box,parts,parttypes,points,zvalues) #,measures)
    end

    function read(io::IO,::Type{Handle})
        code = bswap(read(io,Int32))
        read(io,Int32,5)
        fileSize = bswap(read(io,Int32))
        version = read(io,Int32)
        shapeType = read(io,Int32)
        MBR = read(io,Rect{Float64})
        zmin = read(io,Float64)
        zmax = read(io,Float64)
        mmin = read(io,Float64)
        mmax = read(io,Float64)
        jltype = SHAPETYPE[shapeType]
        shapes = Array{jltype}(0)
        file = Handle(code,fileSize,version,shapeType,MBR,Interval(zmin,zmax),Interval(mmin,mmax),shapes)
        while(!eof(io))
            num = bswap(read(io,Int32))
            rlength = bswap(read(io,Int32))
            shapeType = read(io,Int32)
            push!(shapes, read(io, jltype))
        end
        file
    end

    include("geo_interface.jl")
    #If Compose.jl is present, define useful interconversion functions
    isdefined(:Compose) && isa(Compose, Module) && include("compose.jl")
end # module
