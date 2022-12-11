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
    contentlen::Int32
end

function Base.read(io::IO, ir::Type{IndexRecord})
    IndexRecord(ntoh(read(io, Int32)), ntoh(read(io, Int32)))
end

function Base.write(io::IO, ir::IndexRecord)
    Base.write(io, hton(ir.offset), hton(ir.contentlen))
end

struct IndexHandle
    header::Header
    indices::Vector{IndexRecord}
end

function Base.read(io::IO,  ::Type{IndexHandle})
    header = read(io, Header)
    records = Vector{IndexRecord}(undef,  0)
    while !eof(io)
        push!(records, read(io, IndexRecord))
    end
    return IndexHandle(header, records)
end

function Base.write(io::IO,  ih::IndexHandle)
    bytes = Base.write(io, ih.header)
    for ir in ih.indices
        bytes += Base.write(io, ir)
    end
    return bytes
end
