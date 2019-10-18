import GeoInterface, DBFTables, Tables

"Shapefile.Table represents both the geometries and associated fields"
struct Table{T}
    shp::Handle{T}
    dbf::DBFTables.Table
    # ensure matching sizes on construction
    function Table{T}(shp, dbf) where {T}
        if length(shp) != length(dbf)
            throw(ArgumentError("Shapefile and DBF file contain a different amount of rows"))
        end
        new{T}(shp, dbf)
    end
end

function Table(shp::Handle{T}, dbf::DBFTables.Table) where {T}
    Table{T}(shp, dbf)
end

"Read a file into a Shapefile.Table"
function Table(path::AbstractString)
    stempath, ext = splitext(path)
    if lowercase(ext) == ".shp"
        shp_path = path
        dbf_path = string(stempath, ".dbf")
    elseif ext == ""
        shp_path = string(stempath, ".shp")
        dbf_path = string(stempath, ".dbf")
    else
        throw(ArgumentError("Provide the shapefile with either .shp or no extension"))
    end
    isfile(shp_path) || throw(ArgumentError("File not found: $shp_path"))
    isfile(dbf_path) || throw(ArgumentError("File not found: $dbf_path"))

    shp = open(shp_path) do io
        read(io, Shapefile.Handle)
    end
    dbf = DBFTables.Table(dbf_path)
    return Shapefile.Table(shp, dbf)
end

"Struct representing a singe record in a shapefile"
struct Row{T}
    geometry::T
    record::DBFTables.Row
end

getshp(t::Table) = getfield(t, :shp)
getdbf(t::Table) = getfield(t, :dbf)

Base.length(t::Table) = length(getshp(t).shapes)

Tables.istable(::Type{<:Table}) = true
Tables.rows(t::Table) = t
Tables.columns(t::Table) = t
Tables.rowaccess(::Type{<:Table}) = true
Tables.columnaccess(::Type{<:Table}) = true

"Iterate over the rows of a Shapefile.Table, yielding a Shapefile.Row for each row"
function Base.iterate(t::Table, st = 1)
    st > length(t) && return nothing
    geom = @inbounds getshp(t).shapes[st]
    record = DBFTables.Row(getdbf(t), st)
    return Row(geom, record), st + 1
end

Base.getproperty(row::Row, name::Symbol) = getproperty(getfield(row, :record), name)
Base.getproperty(t::Table, name::Symbol) = getproperty(getdbf(t), name)

Base.propertynames(row::Row) = propertynames(getfield(row, :record))
Base.propertynames(t::Table) = propertynames(getdbf(t))

Tables.schema(t::Table) = Tables.schema(getdbf(t))

function Base.show(io::IO, t::Table)
    tt = typeof(t)
    nr = length(t)
    nc = length(propertynames(t))
    println(io, "$tt with $nr rows and the following $nc columns:\n\t")
    join(io, propertynames(t), ", ")
    println(io)
end

# TODO generalize these with a future GeoInterface/GeoTables
# should probably be geometry/geometries but don't want to claim these names yet
"Get the geometry associated with a shapefile row"
shape(row::Row) = getfield(row, :geometry)
"Get a vector of the geometries in a shapefile, without any metadata"
shapes(t::Table) = getshp(t).shapes
