#
# ERSI Shapefile's index file
#   It contains the same `.shp` 100-bytes header
#   Each index record is 8-bytes long:
#       1. 4-bytes (Int32) offset from the file position 0.
#          the offset is in the unit of 16-bit, i.e. need to multiply 2 to get bytes
#       2. 4-bytes (Int32) content length, without the 8-bytes record header
#          to get total number of bytes: (content length)*2 + 8
#
struct IndexRecord
    offset::Int32
    contentLen::Int32
end

struct IndexHandle
    code::Int32
    length::Int32
    version::Int32
    shapeType::Int32
    MBR::Rect
    zrange::Interval
    mrange::Interval
    indices::Vector{IndexRecord}
end

function Base.read(io::IO,::Type{IndexHandle})
    code = ntoh(read(io,Int32))
    read!(io, Vector{Int32}(undef, 5))
    fileSize = ntoh(read(io,Int32))
    version = read(io,Int32)
    shapeType = read(io,Int32)
    MBR = read(io,Rect)
    zmin = read(io,Float64)
    zmax = read(io,Float64)
    mmin = read(io,Float64)
    mmax = read(io,Float64)
    jltype = SHAPETYPE[shapeType]
    records = Vector{IndexRecord}(undef, 0)
    file = IndexHandle(code,fileSize,version,shapeType,MBR,Interval(zmin,zmax),Interval(mmin,mmax),records)
    while !eof(io)
        push!(records, IndexRecord(ntoh(read(io,Int32)),ntoh(read(io,Int32))))
    end
    file
end
