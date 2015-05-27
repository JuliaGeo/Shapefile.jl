module Shapefile
    import Base: read, show, +, /, ./

    export Handle, RGBGradient, LogLinearRGBGradient, LinearRGBGradient
 
    type Rect{T}
        top::T
        left::T
        bottom::T
        right::T
    end
 
    abstract ESRIShape
 
    type NullShape <: ESRIShape
    end
 
    type Interval{T}
        left::T
        right::T
    end
 
    type Point{T} <: ESRIShape
        x::T
        y::T
    end
 
    +{T}(a::Point{T},b::Point{T}) = Point{T}(a.x+b.x,a.y+b.y)
    /{T}(a::Point{T},val::Real) = Point{T}(a.x/val,a.y/val)
    ./{T}(a::Point{T},val::Real) = Point{T}(a.x./val,a.y./val)

    type PointM{T,M} <: ESRIShape
        x::T
        y::T
        m::M # measure
    end

    type PointZ{T,M} <: ESRIShape
        x::T
        y::T
        z::T
        m::M # measure
    end
 
    type Polyline{T} <: ESRIShape
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
    end

    type PolylineM{T,M} <: ESRIShape
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
        measures::Vector{M}
    end

    type PolylineZ{T,M} <: ESRIShape
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
        zvalues::Vector{T}
        measures::Vector{M}
    end
 
    type Polygon{T} <: ESRIShape
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
    end
 
    show{T}(io::IO,p::Polygon{T}) = print(io,"Polygon(",length(p.points)," ",T," Points)")

    type PolygonM{T,M} <: ESRIShape
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
        measures::Vector{M}
    end

    type PolygonZ{T,M} <: ESRIShape
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
        zvalues::Vector{T}
        measures::Vector{M}
    end
 
    type MultiPoint{T} <: ESRIShape
        MBR::Rect{T}
        points::Vector{Point{T}}
    end

    type MultiPointM{T,M} <: ESRIShape
        MBR::Rect{T}
        points::Vector{Point{T}}
        measures::Vector{M}
    end

    type MultiPointZ{T,M} <: ESRIShape
        MBR::Rect{T}
        points::Vector{Point{T}}
        zvalues::Vector{T}
        measures::Vector{M}
    end

    type MultiPatch{T,M} <: ESRIShape
        MBR::Rect{T}
        parts::Vector{Int32}
        parttypes::Vector{Int32}
        points::Vector{Point{T}}
        zvalues::Vector{T}
        # measures::Vector{M} # (optional)
    end

    type Handle
        code::Int32
        length::Int32
        version::Int32
        shapeType::Int32
        MBR::Rect{Float64}
        zrange::Interval{Float64}
        mrange::Interval{Float64}
        shapes::Vector{ESRIShape}
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
        parts = Array(Int32,numparts)
        read!(io, parts)
        points = Array(Point{T},numpoints)
        read!(io, points)
        Polyline{T}(box,parts,points)
    end

    function read{T,M}(io::IO,::Type{PolylineM{T,M}})
        box = read(io,Rect{T})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array(Int32,numparts)
        read!(io, parts)
        points = Array(Point{T},numpoints)
        read!(io, points)
        mrange = Array(M,2)
        read!(io, mrange)
        measures = Array(M,numpoints)
        read!(io, measures)
        PolylineM{T,M}(box,parts,points,measures)
    end

    function read{T,M}(io::IO,::Type{PolylineZ{T,M}})
        box = read(io,Rect{T})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array(Int32,numparts)
        read!(io, parts)
        points = Array(Point{T},numpoints)
        read!(io, points)
        zrange = Array(T,2)
        read!(io, zrange)
        zvalues = Array(T,numpoints)
        read!(io, zvalues)
        mrange = Array(M,2)
        read!(io, mrange)
        measures = Array(M,numpoints)
        read!(io, measures)
        PolylineZ{T,M}(box,parts,points,zvalues,measures)
    end
 
    function read{T}(io::IO,::Type{Polygon{T}})
        box = read(io,Rect{Float64})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array(Int32,numparts)
        read!(io, parts)
        points = Array(Point{T},numpoints)
        read!(io, points)
        Polygon{T}(box,parts,points)
    end

    function read{T,M}(io::IO,::Type{PolygonM{T,M}})
        box = read(io,Rect{Float64})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array(Int32,numparts)
        read!(io, parts)
        points = Array(Point{T},numpoints)
        read!(io, points)
        mrange = Array(M,2)
        read!(io, mrange)
        measures = Array(M,numpoints)
        read!(io, measures)
        PolygonM{T,M}(box,parts,points,measures)
    end

    function read{T,M}(io::IO,::Type{PolygonZ{T,M}})
        box = read(io,Rect{Float64})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array(Int32,numparts)
        read!(io, parts)
        points = Array(Point{T},numpoints)
        read!(io, points)
        zrange = Array(T,2)
        read!(io, zrange)
        zvalues = Array(T,numpoints)
        read!(io, zvalues)
        mrange = Array(M,2)
        read!(io, mrange)
        measures = Array(M,numpoints)
        read!(io, measures)
        PolygonZ{T,M}(box,parts,points,zvalues,measures)
    end

    function read{T}(io::IO,::Type{MultiPoint{T}})
        box = read(io,Rect{Float64})
        numpoints = read(io,Int32)
        points = Array(Point{T},numpoints)
        read!(io, points)
        MultiPoint{T}(box,points)
    end

    function read{T,M}(io::IO,::Type{MultiPointM{T,M}})
        box = read(io,Rect{Float64})
        numpoints = read(io,Int32)
        points = Array(Point{T},numpoints)
        read!(io, points)
        mrange = Array(M,2)
        read!(io, mrange)
        measures = Array(M,numpoints)
        read!(io, measures)
        MultiPointM{T,M}(box,points,measures)
    end

    function read{T,M}(io::IO,::Type{MultiPointZ{T,M}})
        box = read(io,Rect{Float64})
        numpoints = read(io,Int32)
        points = Array(Point{T},numpoints)
        read!(io, points)
        zrange = Array(T,2)
        read!(io, zrange)
        zvalues = Array(T,numpoints)
        read!(io, zvalues)
        mrange = Array(M,2)
        read!(io, mrange)
        measures = Array(M,numpoints)
        read!(io, measures)
        MultiPointZ{T,M}(box,points,zvalues,measures)
    end

    function read{T,M}(io::IO,::Type{MultiPatch{T,M}})
        box = read(io,Rect{Float64})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array(Int32,numparts)
        read!(io, parts)
        parttypes = Array(Int32,numparts)
        read!(io, parttypes)
        points = Array(Point{T},numpoints)
        read!(io, points)
        zrange = Array(T,2)
        read!(io, zrange)
        zvalues = Array(T,numpoints)
        read!(io, zvalues)
        # mrange = Array(M,2)
        # read!(io, mrange)
        # measures = Array(M,numpoints)
        # read!(io, measures)
        MultiPatch{T,M}(box,parts,parttypes,points,zvalues) #,measures)
    end
 
    function read(io::IO,::Type{ESRIShape})
        num = bswap(read(io,Int32))
        rlength = bswap(read(io,Int32))
        shapeType = read(io,Int32)
        if(shapeType == 0)
            return read(io,NullShape)
        elseif(shapeType == 1)
            return read(io,Point{Float64})
        elseif(shapeType == 3)
            return read(io,Polyline{Float64})
        elseif(shapeType == 5)
            return read(io,Polygon{Float64})
        elseif(shapeType == 8)
            return read(io,MultiPoint{Float64})
        elseif(shapeType == 11)
            return read(io,PointZ{Float64,Float64})
        elseif(shapeType == 13)
            return read(io,PolylineZ{Float64,Float64})
        elseif(shapeType == 15)
            return read(io,PolygonZ{Float64,Float64})
        elseif(shapeType == 18)
            return read(io,MultiPointZ{Float64,Float64})
        elseif(shapeType == 21)
            return read(io,PointM{Float64,Float64})
        elseif(shapeType == 23)
            return read(io,PolylineM{Float64,Float64})
        elseif(shapeType == 25)
            return read(io,PolygonM{Float64,Float64})
        elseif(shapeType == 28)
            return read(io,MultiPointM{Float64,Float64})
        elseif(shapeType == 31)
            return read(io,MultiPatch{Float64,Float64})
        else
            error("Unknown shape type $shapeType")
        end
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
        shapes = Array(ESRIShape,0)
        file = Handle(code,fileSize,version,shapeType,MBR,Interval(zmin,zmax),Interval(mmin,mmax),shapes)
        while(!eof(io))
            push!(shapes,read(io,ESRIShape))
        end
        file
    end
    
    #If Compose.jl is present, define useful interconversion functions
    isdefined(:Compose) && isa(Compose, Module) && include("compose.jl")
end # module
