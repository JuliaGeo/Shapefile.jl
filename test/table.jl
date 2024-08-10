using Shapefile
using Test
using RemoteFiles
using Plots
using Makie
import DBFTables
import DataAPI
import Tables
import DataFrames
import GeoInterface
import GeoFormatTypes

datadir = joinpath(@__DIR__, "data")
url = "https://github.com/nvkelso/natural-earth-vector/raw/v4.1.0"

@RemoteFileSet natural_earth "Natural Earth 110m" begin
    # polygon
    ne_land_shp = @RemoteFile "$url/110m_physical/ne_110m_land.shp" dir = datadir
    ne_land_shx = @RemoteFile "$url/110m_physical/ne_110m_land.shx" dir = datadir
    ne_land_dbf = @RemoteFile "$url/110m_physical/ne_110m_land.dbf" dir = datadir
    ne_land_prj = @RemoteFile "$url/110m_physical/ne_110m_land.prj" dir = datadir
    # linestring
    ne_coastline_shp = @RemoteFile "$url/110m_physical/ne_110m_coastline.shp" dir = datadir
    ne_coastline_shx = @RemoteFile "$url/110m_physical/ne_110m_coastline.shx" dir = datadir
    ne_coastline_dbf = @RemoteFile "$url/110m_physical/ne_110m_coastline.dbf" dir = datadir
    ne_coastline_prj = @RemoteFile "$url/110m_physical/ne_110m_coastline.prj" dir = datadir
    # point
    ne_cities_shp = @RemoteFile "$url/110m_cultural/ne_110m_populated_places_simple.shp" dir = datadir
    ne_cities_shx = @RemoteFile "$url/110m_cultural/ne_110m_populated_places_simple.shx" dir = datadir
    ne_cities_dbf = @RemoteFile "$url/110m_cultural/ne_110m_populated_places_simple.dbf" dir = datadir
    ne_cities_prj = @RemoteFile "$url/110m_cultural/ne_110m_populated_places_simple.prj" dir = datadir
end

download(natural_earth)

@testset "Tables interface" begin

@test isfile(natural_earth)

# create tables that we can use in the tests below
ne_land = Shapefile.Table(path(natural_earth, "ne_land_shp"))
ne_coastline = Shapefile.Table(path(natural_earth, "ne_coastline_shp"))
ne_cities = Shapefile.Table(path(natural_earth, "ne_cities_shp"))

@testset "write tables" begin
    for tbl in (ne_land, ne_coastline, ne_cities)
        file = tempname()
        Shapefile.write(file, tbl)
        tbl2 = Shapefile.Table(file)
        @test Tables.schema(tbl) == Tables.schema(tbl2)
        for prop in propertynames(tbl)
            a, b = getproperty(tbl, prop), getproperty(tbl2, prop)
            if eltype(a) <: Union{Missing, String}
                # ne_cities has non-ascii characters
                @test all(isequal.(
                    skipmissing(a),#replace.(skipmissing(a), !isascii => x -> '_' ^ textwidth(x)),
                    skipmissing(b)
                ))
            else
                @test all(isequal.(a, b))
            end
        end
    end
end

@testset "Create from parts" begin
    ne_land_shp = open(path(natural_earth, "ne_land_shp")) do io
        read(io, Shapefile.Handle)
    end
    ne_land_dbf = open(path(natural_earth, "ne_land_dbf")) do io
        DBFTables.Table(io)
    end
    ne_land_parts = Shapefile.Table(ne_land_shp, ne_land_dbf)

    @test ne_land_shp isa Shapefile.Handle{Union{Shapefile.Polygon,Missing}}
    @test ne_land_dbf isa DBFTables.Table
    @test ne_land_parts isa Shapefile.Table
end

# without .shp extension it should also work
@test Shapefile.Table(splitext(path(natural_earth, "ne_land_shp"))[1]) isa Shapefile.Table

wkt = "GEOGCS[\"GCS_WGS_1984\",DATUM[\"D_WGS_1984\",SPHEROID[\"WGS_1984\",6378137.0,298.257223563]],PRIMEM[\"Greenwich\",0.0],UNIT[\"Degree\",0.017453292519943295]]"

@testset "ne_land" begin
    @test ne_land isa Shapefile.Table{Union{Shapefile.Polygon,Missing}}
    @test length(ne_land) == 127
    @test count(true for r in ne_land) == length(ne_land)
    @test propertynames(ne_land) == [:geometry, :featurecla, :scalerank, :min_zoom]
    @test propertynames(first(ne_land)) == [:geometry, :featurecla, :scalerank, :min_zoom]
    @test first(ne_land).geometry isa Shapefile.Polygon
    @test ne_land.featurecla isa Vector{Union{String,Missing}}
    @test length(ne_land.scalerank) == length(ne_land)
    @test GeoInterface.crs(ne_land) == GeoFormatTypes.ESRIWellKnownText(GeoFormatTypes.CRS(), wkt)

    @test sum(ne_land.scalerank) == 58
    @test Shapefile.shapes(ne_land) isa Vector{Union{Shapefile.Polygon,Missing}}
    @test Tables.istable(ne_land)
    @test Tables.rows(ne_land) === ne_land
    @test Tables.columns(ne_land) === ne_land
    @test Tables.rowaccess(ne_land)
    @test Tables.columnaccess(ne_land)
    @test Tables.schema(ne_land) == Tables.Schema(
        (:geometry, :featurecla, :scalerank, :min_zoom),
        (Union{Missing, Shapefile.Polygon}, Union{String,Missing}, Union{Int,Missing}, Union{Float64,Missing}),
    )
    # Test DataAPI implementation
    @test isempty(setdiff(DataAPI.metadatakeys(ne_land), ("GEOINTERFACE:geometrycolumns", "GEOINTERFACE:crs")))
    @test DataAPI.metadata(ne_land; style = false) isa Dict
    @test DataAPI.metadata(ne_land, "GEOINTERFACE:geometrycolumns"; style = false) == (:geometry,)
    @test DataAPI.metadata(ne_land, "GEOINTERFACE:crs"; style = false) == GeoInterface.crs(ne_land)
    for r in ne_land
        @test Shapefile.shape(r) isa Shapefile.Polygon
        @test r.featurecla == "Land"
    end
    df_land = DataFrames.DataFrame(ne_land)
    @test size(df_land) == (127, 4)
    @test names(df_land) == ["geometry", "featurecla", "scalerank", "min_zoom"]
    df_land.featurecla isa Vector{Union{String,Missing}}
    @test DataAPI.metadata(df_land, "GEOINTERFACE:geometrycolumns"; style = false) == (:geometry,)
    @test DataAPI.metadata(df_land, "GEOINTERFACE:crs"; style = false) == GeoInterface.crs(ne_land)
end

@testset "ne_coastline" begin
    @test ne_coastline isa Shapefile.Table{Union{Shapefile.Polyline,Missing}}
    @test length(ne_coastline) == 134
    @test count(true for r in ne_coastline) == length(ne_coastline)
    @test propertynames(ne_coastline) == [:geometry, :scalerank, :featurecla, :min_zoom]
    @test propertynames(first(ne_coastline)) == [:geometry, :scalerank, :featurecla, :min_zoom]
    @test first(ne_coastline).geometry isa Shapefile.Polyline
    @test ne_coastline.featurecla isa Vector{Union{String,Missing}}
    @test GeoInterface.crs(ne_coastline) == GeoFormatTypes.ESRIWellKnownText(GeoFormatTypes.CRS(), wkt)
    @test length(ne_coastline.scalerank) == length(ne_coastline)
    @test sum(ne_coastline.scalerank) == 59
    @test Shapefile.shapes(ne_coastline) isa Vector{Union{Shapefile.Polyline,Missing}}
    @test Tables.istable(ne_coastline)
    @test Tables.rows(ne_coastline) === ne_coastline
    @test Tables.columns(ne_coastline) === ne_coastline
    @test Tables.rowaccess(ne_coastline)
    @test Tables.columnaccess(ne_coastline)
    @test Tables.schema(ne_coastline) == Tables.Schema(
        (:geometry, :scalerank, :featurecla, :min_zoom),
        (Union{Missing, Shapefile.Polyline}, Union{Int,Missing}, Union{String,Missing}, Union{Float64,Missing}),
    )
    for r in ne_coastline
        @test Shapefile.shape(r) isa Shapefile.Polyline
        @test r.featurecla in ("Coastline", "Country")
    end
    df_coastline = DataFrames.DataFrame(ne_coastline)
    @test size(df_coastline) == (134, 4)
    @test names(df_coastline) == ["geometry", "scalerank", "featurecla", "min_zoom"]
    df_coastline.featurecla isa Vector{Union{String,Missing}}
    @test DataAPI.metadata(df_coastline, "GEOINTERFACE:geometrycolumns"; style = false) == (:geometry,)
    @test DataAPI.metadata(df_coastline, "GEOINTERFACE:crs"; style = false) == GeoInterface.crs(ne_coastline)
end

@testset "ne_cities" begin
    @test ne_cities isa Shapefile.Table{Union{Shapefile.Point,Missing}}
    @test length(ne_cities) == 243
    @test count(true for r in ne_cities) == length(ne_cities)
    colnames = [
        :geometry, :scalerank, :natscale, :labelrank, :featurecla, :name, :namepar, :namealt, :diffascii,
        :nameascii, :adm0cap, :capalt, :capin, :worldcity, :megacity, :sov0name, :sov_a3,
        :adm0name, :adm0_a3, :adm1name, :iso_a2, :note, :latitude, :longitude, :changed,
        :namediff, :diffnote, :pop_max, :pop_min, :pop_other, :rank_max, :rank_min, :geonameid,
        :meganame, :ls_name, :ls_match, :checkme, :min_zoom, :ne_id,
    ]
    @test propertynames(ne_cities) == colnames
    @test propertynames(first(ne_cities)) == colnames
    @test first(ne_cities).geometry isa Shapefile.Point
    @test ne_cities.featurecla isa Vector{Union{String,Missing}}
    @test GeoInterface.crs(ne_coastline) == GeoFormatTypes.ESRIWellKnownText(GeoFormatTypes.CRS(), wkt)
    @test length(ne_cities.scalerank) == length(ne_cities)
    @test sum(ne_cities.scalerank) == 612
    @test Shapefile.shapes(ne_cities) isa Vector{Union{Shapefile.Point,Missing}}
    @test Tables.istable(ne_cities)
    @test Tables.rows(ne_cities) === ne_cities
    @test Tables.columns(ne_cities) === ne_cities
    @test Tables.rowaccess(ne_cities)
    @test Tables.columnaccess(ne_cities)
    classes = ["Admin-0 capital", "Admin-0 capital alt", "Populated place",
        "Admin-1 capital", "Admin-1 region capital", "Admin-0 region capital"]
    @test unique(ne_cities.featurecla) == classes
    for r in ne_cities
        @test Shapefile.shape(r) isa Shapefile.Point
        @test r.featurecla in classes
    end
    show_result = "Shapefile.Table{Union{Missing, Point}} with 243 rows and the following 39 columns:\n\t\ngeometry, scalerank, natscale, labelrank, featurecla, name, namepar, namealt, diffascii, nameascii, adm0cap, capalt, capin, worldcity, megacity, sov0name, sov_a3, adm0name, adm0_a3, adm1name, iso_a2, note, latitude, longitude, changed, namediff, diffnote, pop_max, pop_min, pop_other, rank_max, rank_min, geonameid, meganame, ls_name, ls_match, checkme, min_zoom, ne_id\n"
    if VERSION < v"1.1"
        show_result = replace(show_result, "Shapefile.Point" => "Point")
    end
    @test sprint(
            show,
            ne_cities,
        ) === show_result
    df_cities = DataFrames.DataFrame(ne_cities)
    @test size(df_cities) == (243, 39)
    @test names(df_cities) == string.(colnames)
    df_cities.featurecla isa Vector{Union{String,Missing}}
    @test DataAPI.metadata(df_cities, "GEOINTERFACE:geometrycolumns"; style = false) == (:geometry,)
    @test DataAPI.metadata(df_cities, "GEOINTERFACE:crs"; style = false) == GeoInterface.crs(ne_cities)
end

# no need to use shx in Shapefile.Tables since we read the shapes into a Vector and can thus index them
# but since we have these files, we may as well try reading them
ne_shx = [path(rfs) for rfs in files(natural_earth) if endswith(path(rfs), ".shx")]
@test length(ne_shx) == 3
for shx_path in ne_shx
    open(path(natural_earth, "ne_land_shx")) do io
        read(io, Shapefile.IndexHandle)
    end
end


@testset "plot tables with Plots.jl" begin
    # Tables
    Plots.plot(ne_land)
    Plots.plot(ne_coastline)
    Plots.plot(ne_cities)
    # Handles
    Plots.plot(getfield(ne_land, :shp))
    Plots.plot(getfield(ne_coastline, :shp))
    Plots.plot(getfield(ne_cities, :shp))
end

@testset "plot tables with Makie.jl" begin
    # Tables
    p = Makie.plot(ne_land)
    # Makie doesn't actually plot vectors of multiline string:
    # Makie.plot(ne_coastline)
    # So we do it manually
    for geom in Shapefile.shapes(ne_coastline)
        Makie.plot!(p.axis, geom)
    end
    Makie.plot!(p.axis, ne_cities)
    # Handles
    p = Makie.plot(getfield(ne_land, :shp))
    # Makie doesn't actually plot vectors of multiline string:
    # Makie.plot(ne_coastline)
    # So we do it manually
    for geom in Shapefile.shapes(getfield(ne_coastline, :shp))
        Makie.plot!(p.axis, geom)
    end
    Makie.plot!(p.axis, getfield(ne_cities, :shp))
end

end  # testset "Tables interface"

@testset "Reading with ZipFile" begin
    using ZipFile
    @test !isnothing(Base.get_extension(Shapefile, :ShapefileZipFileExt))
    mktempdir() do dir
        cd(dir) do
            zipfile = @RemoteFile "https://ndownloader.figshare.com/files/20460645" dir=datadir file="tracts.zip"
            download(zipfile)
            @test_nowarn Shapefile.Table(path(zipfile))
            table = Shapefile.Table(path(zipfile))
            # Test that the return type is correct
            @test table isa Shapefile.Table
            # Test that the table is read correctly
            @test length(table) == 822
            @test eltype(table.STATEFP) <: Union{Missing, String}
            # Test that the projection was picked up
            @test GeoInterface.crs(table) isa Shapefile.GeoFormatTypes.ESRIWellKnownText{Shapefile.GeoFormatTypes.CRS}
        end
    end
end

