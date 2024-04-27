import GeoInterface, DBFTables, Tables

"""
    Row

    Row(geometry, record::DBFTables.Row)

A struct representing a single record in a shapefile.

Property names accessable by `row.x` are `geometry` for the
geometry object, and the names of the columns in `record`.
"""
struct Row{T}
    geometry::T
    record::DBFTables.Row
end


function Base.getproperty(row::Row, name::Symbol)
    if name == :geometry
        return getfield(row, :geometry)
    else
        return getproperty(getfield(row, :record), name)
    end
end
Base.propertynames(row::Row) = [:geometry, propertynames(getfield(row, :record))...]

GeoInterface.isfeature(t::Row) = true
GeoInterface.geometry(t::Row) = getfield(t, :geometry)
GeoInterface.properties(t::Row) = getfield(t, :record)

"""
    shape(row::Row)

Get the geometry associated with a `Row` from a shapefile `Table`.
"""
shape(row::Row) = getfield(row, :geometry)

"""
    Table

    Table(path::AbstractString)
    Table(shp::Handle{T}, dbf::DBFTables.Table)

Represents both geometries and their associated fields as a Tables.jl
compatible table, where each row is is a an object such as a (`Point`](@ref),
[`Polyline`](@ref) or [`Polygon`](@ref).

The `Shapefile.Table` constructor can read either a `String` path to
a shapefile, or a [`Shapefile.Handle`](@ref) and a `DBFTables.Table`.

Property names accessable by `table.x` are `geometry` for the
geometry object, and the names of the columns in `dbf`.
"""
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
function Table(path::AbstractString)
    if endswith(path, ".zip")
        return _read_shp_from_zipfile(path)
    end
    paths = _shape_paths(path)
    isfile(paths.shp) || throw(ArgumentError("File not found: $(paths.dbf)"))
    isfile(paths.dbf) || throw(ArgumentError("File not found: $(paths.dbf)"))

    shp = if isfile(paths.shx)
        Shapefile.Handle(paths.shp, paths.shx)
    else
        Shapefile.Handle(paths.shp)
    end
    dbf = DBFTables.Table(paths.dbf)
    return Shapefile.Table(shp, dbf)
end

function _read_shp_from_zipfile end

getshp(t::Table) = getfield(t, :shp)
getdbf(t::Table) = getfield(t, :dbf)

Base.length(t::Table) = length(shapes(t))

Tables.istable(::Type{<:Table}) = true
Tables.rows(t::Table) = t
Tables.columns(t::Table) = t
Tables.rowaccess(::Type{<:Table}) = true
Tables.columnaccess(::Type{<:Table}) = true



"""
    Base.iterate(t::Table)

Iterate over the rows of a Shapefile.Table, yielding a Shapefile.Row for each row.
"""
function Base.iterate(t::Table, st = 1)
    st > length(t) && return nothing
    geom = shapes(t)[st]
    record = DBFTables.Row(getdbf(t), st)
    return Row(geom, record), st + 1
end

function Base.getproperty(t::Table, name::Symbol)
    if name === :geometry
        shapes(t)
    else
        getproperty(getdbf(t), name)
    end
end

function Base.propertynames(t::Table)
    names = propertynames(getdbf(t))
    pushfirst!(names, :geometry)
    return names
end

function Tables.schema(t::Table)
    dbf = getdbf(t)
    dbf_schema = Tables.schema(dbf)
    names = (:geometry, dbf_schema.names...)
    types = (eltype(shapes(t)), dbf_schema.types...)
    return Tables.Schema(names, types)
end

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

"""
    shapes(t::Table)

Get a vector of the geometries in a shapefile `Table`, without any metadata.
"""
shapes(t::Table) = shapes(getshp(t))

GeoInterface.extent(t::Table) = GeoInterface.extent(getshp(t))
GeoInterface.crs(t::Table) = GeoInterface.crs(getshp(t))
