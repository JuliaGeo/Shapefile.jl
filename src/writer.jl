function Base.write(io::IO, rect::Rect)
    bytes = Int32(0)
    bytes += write(io, rect.left)
    bytes += write(io, rect.bottom)
    bytes += write(io, rect.right)
    bytes += write(io, rect.top)
    return bytes
end

function Base.write(io::IO, point::Point)
    bytes = Int32(0)
    bytes += write(io, point.x)
    bytes += write(io, point.y)

    return bytes
end

function Base.write(io::IO, point_m::PointM)
    bytes = Int32(0)

    bytes += write(io, point_m.x )
    bytes += write(io, point_m.y )
    bytes += write(io, point_m.m ) # measure

    return bytes
end

function Base.write(io::IO, point_z::PointZ)

    bytes = Int32(0)

    bytes +=  write(io, point_z.x)
    bytes +=  write(io, point_z.y)
    bytes +=  write(io, point_z.z)
    bytes +=  write(io, point_z.m)

    return bytes
end

# Write an array of Point, PointZ, PointM
function Base.write(io::IO, geo::Array{T}) where T<: Union{Point, PointM, PointZ} 
    bytes = write.(Ref(io), geo)
    return sum(bytes)
end


function Base.write(io::IO, polyline::Polyline)
    bytes = Int32(0)

    mbr_box = polyline.MBR
    numparts  = Int32(length(polyline.parts))
    numpoints = Int32(length(polyline.points))
    
    bytes += write(io, mbr_box)
    bytes += write(io, numparts)
    bytes += write(io, numpoints)
    
    # Write an array of el_type
    bytes += write(io, polyline.parts)
    bytes += write(io, polyline.points)

    return bytes
end

function Base.write(io::IO, polyline_m::PolylineM)
    bytes = Int32(0)

    mbr_box = polyline_m.MBR
    numparts  = Int32(length(polyline_m.parts ))
    numpoints = Int32(length(polyline_m.points ))
    
    bytes += write(io, mbr_box)
    bytes += write(io, numparts)
    bytes += write(io, numpoints)
    
    bytes += write(io, polyline_m.parts)
    bytes += write(io, polyline_m.points)
    
    mrange = extrema(polyline_m.measures)
    bytes += write(io, mrange...)
    bytes += write(io, polyline_m.measures)

    return bytes
end

function Base.write(io::IO, polyline_z::PolylineZ)
    bytes = Int32(0)

    mbr_box = polyline_z.MBR
    numparts  = Int32(length(polyline_z.parts ))
    numpoints = Int32(length(polyline_z.points ))
    
    bytes += write(io, mbr_box)
    bytes += write(io, numparts)
    bytes += write(io, numpoints)

    bytes += write(io, polyline_z.parts)
    bytes += write(io, polyline_z.points)
    
    zrange = extrema(polyline_z.zvalues)
    bytes += write(io, zrange...)
    bytes += write(io, polyline_z.zvalues)
    
    mrange = extrema(polyline_z.measures)
    bytes += write(io, mrange...)
    bytes += write(io, polyline_z.measures)

    return bytes
end

function Base.write(io::IO, polygon::Polygon)
    bytes = Int32(0)

    mbr_box = polygon.MBR
    numparts = Int32(length(polygon.parts))
    numpoints = Int32(length(polygon.points))

    bytes += write(io, mbr_box)
    bytes += write(io, numparts)
    bytes += write(io, numpoints)
    
    bytes += write(io, polygon.parts)
    bytes += write(io, polygon.points)
    
    return bytes
end

function Base.write(io::IO, polygon_m::PolygonM)
    bytes = Int32(0)
    
    mbr_box = polygon_m.MBR
    numparts = Int32(length(polygon_m.parts))
    numpoints = Int32(length(polygon_m.points))
    
    bytes += write(io, mbr_box)
    bytes += write(io, numparts)
    bytes += write(io, numpoints)

    bytes += write(io, polygon_m.parts)
    bytes += write(io, polygon_m.points)

    mrange = extrema(polygon_m.measures)
    bytes += write(io, mrange...)
    bytes += write(io, polygon_m.measures)
    
    return bytes
end

function Base.write(io::IO, polygon_z::PolygonZ)
    bytes = Int32(0)

    mbr_box = polygon_z.MBR
    numparts = Int32(length(polygon_z.parts))
    numpoints = Int32(length(polygon_z.points))
    
    bytes += write(io, mbr_box)
    bytes += write(io, numparts)
    bytes += write(io, numpoints)

    bytes += write(io, polygon_z.parts)
    bytes += write(io, polygon_z.points)

    zrange = extrema(polygon_z.zvalues)
    bytes += write(io, zrange...)
    bytes += write(io, polygon_z.zvalues)

    mrange = extrema(polygon_z.measures)
    bytes += write(io, mrange...)
    bytes += write(io, polygon_z.measures)

    return bytes
end

function Base.write(io::IO, multipoint::MultiPoint)
    bytes = Int32(0)

    mbr_box  = multipoint.MBR
    numpoints = Int32(length(multipoint.points))

    bytes += write(io, mbr_box)
    bytes += write(io, numpoints)
    bytes += write(io, multipoint.points)
    
    return bytes
end

function Base.write(io::IO, multipoint_m::MultiPointM)
    bytes = Int32(0)

    mbr_box = multipoint_m.MBR
    numpoints = Int32(length(multipoint_m.points))
    bytes += write(io, mbr_box)
    bytes += write(io, numpoints)
    bytes += write(io, multipoint_m.points)

    mrange = extrema(multipoint_m.measures)
    bytes += write(io, mrange...)
    bytes += write(io, multipoint_m.measures)

    return bytes
end

function Base.write(io::IO, multipoint_z::MultiPointZ)
    bytes = Int32(0)

    mbr_box = multipoint_z.MBR
    numpoints = Int32(length(multipoint_z.points))

    bytes += write(io, mbr_box)
    bytes += write(io, numpoints)
    bytes += write(io, multipoint_z.points)
    
    zrange = extrema(multipoint_z.zvalues)
    bytes += write(io, zrange...)
    bytes += write(io, multipoint_z.zvalues)

    mrange = extrema(multipoint_z.measures)
    bytes += write(io, mrange...)
    bytes += write(io, multipoint_z.measures)

    return bytes
end

function Base.write(io::IO, multipatch::MultiPatch)
    bytes = Int32(0)
    
    mbr_box = multipatch.MBR
    numparts = Int32(length(multipatch.parts))
    numpoints = Int32(length(multipatch.points))

    bytes += write(io, mbr_box)
    bytes += write(io, numparts)
    bytes += write(io, numpoints)

    bytes += write(io, multipatch.parts)
    bytes += write(io, multipatch.parttypes)
    
    bytes += write(io, multipatch.points)
    
    zrange = extrema(multipatch.zvalues)
    bytes += write(io, zrange...)
    bytes += write(io, multipatch.zvalues)
    
    # mrange = extrema(multipatch.mvalues)
    # bytes += write(io, mrange...)
    # bytes += write(io, multipatch.measures)
    return bytes
end

# Reverse lookup for Shapetype to Code
SHAPECODE = Dict(zip(values(Shapefile.SHAPETYPE), keys(Shapefile.SHAPETYPE)))

get_MBR(shapes::Array{Missing}) = Rect(0,0,0,0)
function get_MBR(shapes::Array{Union{Missing,T}}) where T<:Union{Polyline,Polygon,MultiPoint,PolylineZ,PolygonZ,MultiPointZ,PolylineM,PolygonM,MultiPointM,MultiPatch}
    most_left   = Inf
    most_bottom = Inf
    most_right  = -Inf
    most_top    = -Inf
    for shape in skipmissing(shapes)
        most_left   = min(shape.MBR.left,   most_left)
        most_bottom = min(shape.MBR.bottom, most_bottom)
        most_right  = max(shape.MBR.right,  most_right)
        most_top    = max(shape.MBR.top,    most_top)
    end
    return Rect(most_left, most_bottom, most_right, most_top)
end

function get_MBR(points::Array{Union{Missing,T}}) where T<:Union{Point,PointM,PointZ}
    most_left   = Inf
    most_bottom = Inf
    most_right  = -Inf
    most_top    = -Inf
    for point in skipmissing(points)
        most_left   = min(point.x, most_left)
        most_bottom = min(point.y, most_bottom)
        most_right  = max(point.x, most_right)
        most_top    = max(point.y, most_top)
    end
    return Rect(most_left, most_bottom, most_right, most_top)
end

const GeometriesHasNoZValues = Union{          PolygonM,            PolylineM,              MultiPointM,           Polyline, Polygon, MultiPoint, Point, PointM} # PointZ is speically handled 
const GeometriesHasZValues   = Union{PolygonZ,           PolylineZ,            MultiPointZ,             MultiPatch} 
const GeometriesHasNoMValues = Union{Polyline, Polygon, MultiPoint, Point, MultiPatch} # PointZ, PointM are speically handled
const GeometriesHasMValues   = Union{PolygonZ, PolygonM, PolylineZ, PolylineM, MultiPointZ, MultiPointM}

get_zrange(shapes::Array{Missing}) = Interval(0,0)
get_zrange(shapes::Array{Union{Missing,T}}) where T<:GeometriesHasNoZValues = Interval(0,0)
function get_zrange(shapes::Array{Union{Missing,T}}) where T<:GeometriesHasZValues
    # get z range
    min_z = +Inf
    max_z = -Inf
    for shape in skipmissing(shapes)
        for zvalue in shape.zvalues
            min_z = min(min_z, zvalue)
            max_z = max(max_z, zvalue)
        end 
    end
    return Interval(min_z, max_z)    
end
function get_zrange(points::Array{Union{Missing,T}}) where T<:PointZ
    min_z = +Inf
    max_z = -Inf
    for point in skipmissing(points)
        min_z = min(min_z, point.z)
        max_z = max(max_z, point.z)
    end
    return Interval(min_z, max_z)
end

get_mrange(x::Array{Missing}) = Interval(0,0)
get_mrange(x::Array{Union{Missing,T}}) where T<:GeometriesHasNoMValues = Interval(0.0,0.0)
function get_mrange(shapes::Array{Union{Missing,T}}) where T<:GeometriesHasMValues
    # get m range
    min_m = +Inf
    max_m = -Inf
    for shape in skipmissing(shapes)
        for measure in shape.measures
            min_m = min(min_m, measure)
            max_m = max(max_m, measure)
        end 
    end
    return Interval(min_m, max_m)
end
function get_mrange(points::Array{Union{Missing,T}}) where T<:Union{PointM, PointZ}
    min_m = +Inf
    max_m = -Inf
    for point in skipmissing(points)
        min_m = min(min_m, point.m)
        max_m = max(max_m, point.m)
    end
    return Interval(min_m, max_m)
end

const AllShapeTypes = Union{Point,Polyline,Polygon,MultiPoint,PointZ,PolylineZ,PolygonZ,MultiPointZ,PointM,PolylineM,PolygonM,MultiPointM,MultiPatch}
function Base.write(io::IO, ::Type{Handle}, shapes::Array{Union{Missing,T}}) where T<:AllShapeTypes
    
    # Since all the headers has some sort of content length information before the data block.
    # The code here will write out the data into a IOBuffer first to get the content length.
    # Finally it write the length information and then unload the IOBuffer data into the main block.

    # Define some temorary io buffer to store raw bytes
    geometries_io = IOBuffer()
    record_io     = IOBuffer()

    # Write all the shapes into a main block of data (geometries_io)
    content_size = 0
    num          = 0
    rec_length   = 0

    
    # NOTE:
    # Since if we are allowing shapes to be an array of Union{Missing,AllShapeType}
    # We have to default the base shapefile is Null shape
    # Until there is AT LEAST ONE non-null shape type
    # Then we will set the whole shapefile as such non-null shape type
    shapeType = SHAPECODE[Missing]
    for shape in shapes
        # One -based record number; Increment from 0, and increment after record.
        num += 1
        
        # Write Record to temorary buffer first
        bytes = 0
        if !ismissing(shape)
            shapeType = SHAPECODE[typeof(shape)]
            bytes += write( record_io, shapeType)
            bytes += write( record_io, shape)
        else
            # Null Shape
            bytes += write( record_io, SHAPECODE[Missing])
        end
        
        @assert bytes == record_io.size "The hardcoded accumulation of bytes should match how much bytes it has written into the buffer!"

        # Record Header
        # 32-bits (4 bytes) Record Number + 32-bits (4 bytes) Content length = 8 bytes
        rec_length = bytes + 8 
        write( geometries_io, bswap(Int32(num)))
        
        # Record length measured in 16-bit words (1-unit is 2-bytes (16-bits))
        # So we divide record length recorded in bytes (8-bits) by 2 into 1 unit (16-bit/2 bytes) 
        write( geometries_io, bswap(Int32(bytes /2)))
        write( geometries_io, take!(record_io))
        
        content_size += rec_length

        # !TODO: Here is where we extract and store the shx file content offset number        

         
    end

    # 
    # Generate Basic File header information
    #
    code        = 9994
    file_length = content_size + 100 
    version     = 1000
    
    #
    # Compute Shape-dependent information
    #   1. MBR; Minimul Bounding Region, a up-right rectangular lat,lon box encapsulating all data point. 
    #   2. zrange; An 1-dimensional interval encapsulating all z-values presented in the data 
    #   3. mrange; An 1-dimensional interval encapsulating all measurements values presented in the data
    #
    MBR = get_MBR(shapes)
    zrange = get_zrange(shapes)
    mrange = get_mrange(shapes)

    #
    # Write File Header Information into file
    #
    bytes = 0
    bytes += write(io, bswap(Int32(code)))
    # code = bswap(read(io, Int32))

    bytes += write(io, Int32[0,0,0,0,0])
    # read!(io, Vector{Int32}(undef, 5))
    
    # !NOTE: Record in 16-bits words
    bytes += write(io, bswap(Int32(file_length/2)))
    # content_size = bswap(read(io, Int32))
    
    bytes += write(io, Int32(version))
    # version = read(io, Int32)

    bytes += write(io, Int32(shapeType))
    # shapeType = read(io, Int32)
    
    bytes += write(io, MBR)
    # MBR = read(io, Rect)
    
    bytes += write(io, zrange.left)
    bytes += write(io, zrange.right)
    # zmin = read(io, Float64)
    # zmax = read(io, Float64)
    
    bytes += write(io, mrange.left)
    bytes += write(io, mrange.right)
    # mmin = read(io, Float64)
    # mmax = read(io, Float64)
    @show bytes

    # Write the maind block of data into the rest of the shape file
    write(io, take!(geometries_io))
    
end