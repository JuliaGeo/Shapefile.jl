module Shapefile
    import Base.read, Base.show, Base.ref, Base.+, Base.(/), Base.(./)
    
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
 
    type Polyline{T} <: ESRIShape
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
    end
 
    type Polygon{T} <: ESRIShape
        MBR::Rect{T}
        parts::Vector{Int32}
        points::Vector{Point{T}}
    end
 
    show{T}(io::IO,p::Polygon{T}) = print(io,"Polygon(",length(p.points)," ",T," Points)")
 
    type MultiPoint{T} <: ESRIShape
        MBR::Rect{T}
        numpart::Int32
        numpoints::Int32
        parts::Vector{ESRIShape}
        points::Vector{Point{T}}
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
 
    function read{T}(io::IO,::Type{Point{T}})
        x = read(io,T)
        y = read(io,T)
        Point{T}(x,y)
    end
 
    function read{T}(io::IO,::Type{Polyline{T}})
        box = read(IO,Rect{Float64})
        numparts = read(IO,Int32)
        numpoints = read(IO,Int32)
        parts = Array(Int32,numparts)
        read(io, parts)
        points = Array(Point{T},num)
        read(io, points)
        Polyline{T}(box,parts,points)
    end
 
    function read{T}(io::IO,::Type{Polygon{T}})
        box = read(io,Rect{Float64})
        numparts = read(io,Int32)
        numpoints = read(io,Int32)
        parts = Array(Int32,numparts)
        read(io, parts)
        points = Array(Point{T},numpoints)
        read(io, points)
        Polygon{T}(box,parts,points)
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
