module MissingMeasuresTests

using Shapefile, Test
import GeoInterface as GI

# Minimal external GeoInterface geometries allow missing M values as input while
# Shapefile's own geometry fields remain Float64.
struct MeasurePoint{Z,M,T}
    coords::T
end
GI.isgeometry(::Type{<:MeasurePoint}) = true
GI.geomtrait(::MeasurePoint) = GI.PointTrait()
GI.is3d(::GI.PointTrait, ::MeasurePoint{Z}) where Z = Z
GI.ismeasured(::GI.PointTrait, ::MeasurePoint{Z,M}) where {Z,M} = M
GI.ncoord(::GI.PointTrait, ::MeasurePoint{Z,M}) where {Z,M} = 2 + Z + M
GI.coordnames(::GI.PointTrait, ::MeasurePoint{Z,M}) where {Z,M} =
    Z ? (M ? (:X, :Y, :Z, :M) : (:X, :Y, :Z)) : (:X, :Y, :M)
GI.getcoord(::GI.PointTrait, p::MeasurePoint, i) = p.coords[i]

struct MeasureGeometry{T,Z,M,C}
    children::C
end
MeasureGeometry(t, z, m, children) = MeasureGeometry{typeof(t),z,m,typeof(children)}(children)
GI.isgeometry(::Type{<:MeasureGeometry}) = true
GI.geomtrait(::MeasureGeometry{T}) where T = T()
GI.is3d(::GI.AbstractGeometryTrait, ::MeasureGeometry{T,Z}) where {T,Z} = Z
GI.ismeasured(::GI.AbstractGeometryTrait, ::MeasureGeometry{T,Z,M}) where {T,Z,M} = M
GI.ncoord(::GI.AbstractGeometryTrait, ::MeasureGeometry{T,Z,M}) where {T,Z,M} = 2 + Z + M
GI.ngeom(::GI.AbstractGeometryTrait, g::MeasureGeometry) = length(g.children)
GI.getgeom(::GI.AbstractGeometryTrait, g::MeasureGeometry, i) = g.children[i]

function geometry(kind, z, values; measured=true)
    xy = [(0., 0.), (0., 2.), (2., 2.), (2., 0.), (0., 0.)]
    points = map(eachindex(values)) do i
        coords = (xy[i]..., (z ? (0.1i,) : ())..., (measured ? (values[i],) : ())...)
        MeasurePoint{z,measured,typeof(coords)}(coords)
    end
    kind == :point && return only(points)
    kind == :multipoint && return MeasureGeometry(GI.MultiPointTrait(), z, measured, points)
    if kind == :polyline
        line = MeasureGeometry(GI.LineStringTrait(), z, measured, points)
        return MeasureGeometry(GI.MultiLineStringTrait(), z, measured, [line])
    end
    ring = MeasureGeometry(GI.LinearRingTrait(), z, measured, points)
    polygon = MeasureGeometry(GI.PolygonTrait(), z, measured, [ring])
    return MeasureGeometry(GI.MultiPolygonTrait(), z, measured, [polygon])
end

measure_values(g) = GI.geomtrait(g) isa GI.PointTrait ? [GI.m(g)] : [GI.m(p) for p in GI.getpoint(g)]
range_values(r) = (r.left, r.right)

function check_file(path, expected_ranges)
    paths = Shapefile._shape_paths(path)
    index = read(paths.shx, Shapefile.IndexHandle)
    header = read(paths.shp, Shapefile.Header)
    @test 2 * header.filesize == filesize(paths.shp)
    @test 2 * index.header.filesize == filesize(paths.shx)
    @test range_values(header.mrange) == expected_ranges
    @test range_values(index.header.mrange) == expected_ranges
    open(paths.shp) do io
        seek(io, 100)
        for (num, record) in enumerate(index.indices)
            @test position(io) == 2 * record.offset
            @test ntoh(read(io, Int32)) == num
            @test ntoh(read(io, Int32)) == record.contentlen
            seek(io, position(io) + 2 * record.contentlen)
        end
        @test position(io) == filesize(paths.shp)
    end
end

# Remove all or part of the first record's M tail, adjusting both file lengths
# and the index. The following record stays intact to detect reads across it.
function shorten_first_m(path, mbytes, keepbytes)
    paths = Shapefile._shape_paths(path)
    data = read(paths.shp)
    index = read(paths.shx, Shapefile.IndexHandle)
    oldlen = 2 * Int(index.indices[1].contentlen)
    removed = mbytes - keepbytes
    newlen = oldlen - removed
    data = vcat(data[1:108 + newlen], data[109 + oldlen:end])
    open(paths.shp, "w") do io
        Base.write(io, data)
        seek(io, 24)
        Base.write(io, hton(Int32(length(data) ÷ 2)))
        seek(io, 104)
        Base.write(io, hton(Int32(newlen ÷ 2)))
    end
    records = [Shapefile.IndexRecord(r.offset - (i == 1 ? 0 : removed ÷ 2),
        r.contentlen - (i == 1 ? removed ÷ 2 : 0)) for (i, r) in enumerate(index.indices)]
    Base.write(paths.shx, Shapefile.IndexHandle(index.header, records))
end

@testset "Missing measures retain Float64 storage" begin
    mktempdir() do dir
        path = joinpath(dir, "measures")
        nodata = -1.0e39
        cases = ([1., 2., 3., 4., 5.], [-1.e40, 2., 3., 4., 5.],
            fill(-1.e40, 5), [missing, 2., missing, 4., 5.], fill(missing, 5),
            [-1.e38, prevfloat(-1.e38), nextfloat(-1.e38), 0., 1.])
        for kind in (:point, :multipoint, :polyline, :polygon), z in (false, true), values in cases
            input = kind == :point ? values[1:1] : values
            geom = geometry(kind, z, input)
            Shapefile.write(path, geom; force=true)
            expected = [ismissing(m) ? nodata : Float64(m) for m in input]
            valid = filter(m -> m >= -1.e38, expected)
            bounds = isempty(valid) ? (nodata, nodata) : extrema(valid)
            check_file(path, bounds)
            for h in (Shapefile.Handle(path * ".shp"), Shapefile.Handle(path * ".shp", nothing))
                g = only(h.shapes)
                @test measure_values(g) == expected
                @test all(m -> m isa Float64, measure_values(g))
                @test GI.is3d(g) == z
                if kind != :point
                    @test g.measures isa Vector{Float64}
                    @test range_values(g.mrange) == bounds
                else
                    @test g.m isa Float64
                end
            end
        end

        @testset "XYZ input and varying M presence" begin
            for kind in (:point, :multipoint, :polyline, :polygon)
                n = kind == :point ? 1 : 5
                xyz = geometry(kind, true, fill(0., n); measured=false)
                xyzm = geometry(kind, true, fill(7., n))
                for geoms in ([xyz], [xyz, xyzm], [xyzm, xyz], [xyz, missing, xyzm])
                    Shapefile.write(path, Shapefile.Writer(geoms); force=true)
                    check_file(path, length(geoms) == 1 ? (nodata, nodata) : (7., 7.))
                    actual = Shapefile.Table(path).geometry
                    for (before, after) in zip(geoms, actual)
                        if ismissing(before)
                            @test ismissing(after)
                        else
                            @test measure_values(after) == fill(GI.ismeasured(before) ? 7. : nodata, n)
                            beforepts = kind == :point ? [before] : GI.getpoint(before)
                            afterpts = kind == :point ? [after] : GI.getpoint(after)
                            @test [(GI.x(p), GI.y(p), GI.z(p)) for p in afterpts] ==
                                [(GI.x(p), GI.y(p), GI.z(p)) for p in beforepts]
                        end
                    end
                end
            end
        end

        @testset "Sentinels do not affect file bounds" begin
            for z in (false, true), kind in (:point, :multipoint, :polyline, :polygon)
                n = kind == :point ? 1 : 5
                absent = geometry(kind, z, fill(-1.e40, n))
                valid = geometry(kind, z, fill(12., n))
                for geoms in ([absent, valid], [valid, absent], [absent, absent])
                    Shapefile.write(path, Shapefile.Writer(geoms); force=true)
                    check_file(path, geoms == [absent, absent] ? (nodata, nodata) : (12., 12.))
                end
            end
        end

        @testset "Optional and truncated M blocks" begin
            for kind in (:point, :multipoint, :polyline, :polygon), z in (false, true)
                kind == :point && !z && continue # PointM requires its measure.
                n = kind == :point ? 1 : 5
                mbytes = kind == :point ? 8 : 16 + 8n
                geom = geometry(kind, z, fill(7., n))
                Shapefile.write(path, Shapefile.Writer([geom, missing, geom]); force=true)
                shorten_first_m(path, mbytes, 0)
                for h in (Shapefile.Handle(path * ".shp"), Shapefile.Handle(path * ".shp", nothing))
                    @test measure_values(h.shapes[1]) == fill(nodata, n)
                    @test ismissing(h.shapes[2])
                    @test measure_values(h.shapes[3]) == fill(7., n)
                    if kind != :point
                        @test range_values(h.shapes[1].mrange) == (nodata, nodata)
                    end
                end
                for keep in (kind == :point ? (2, 6) : (2, 8, 16, mbytes - 2))
                    Shapefile.write(path, [geom, geom]; force=true)
                    shorten_first_m(path, mbytes, keep)
                    @test_throws ArgumentError Shapefile.Handle(path * ".shp")
                    @test_throws ArgumentError Shapefile.Handle(path * ".shp", nothing)
                end
                # An omitted tail in the last record is also valid.
                Shapefile.write(path, geom; force=true)
                shorten_first_m(path, mbytes, 0)
                @test measure_values(only(Shapefile.Handle(path * ".shp").shapes)) == fill(nodata, n)
                @test measure_values(only(Shapefile.Handle(path * ".shp", nothing).shapes)) == fill(nodata, n)

                # A physically truncated block advertised as complete is not absent.
                Shapefile.write(path, geom; force=true)
                open(path * ".shp", "r+") do io
                    truncate(io, filesize(path * ".shp") - 2)
                end
                @test_throws EOFError Shapefile.Handle(path * ".shp")
            end

            pointm = geometry(:point, false, [7.])
            Shapefile.write(path, [pointm, pointm]; force=true)
            shorten_first_m(path, 8, 0)
            @test_throws ArgumentError Shapefile.Handle(path * ".shp")

            for m in (NaN, Inf, -Inf)
                @test_throws ArgumentError Shapefile._write(IOBuffer(), geometry(:point, true, [m]))
                @test_throws ArgumentError Shapefile._write(IOBuffer(), geometry(:multipoint, true, fill(m, 5)))
            end
        end

        @testset "Issue 28 example" begin
            lr = GI.LinearRing{true,false}([(0., 0., 0.04), (1.5, 2.5, 0.05),
                (3.2, 2.3, 0.06), (2.4, 1.2, 0.04), (0., 0., 0.04)])
            mp = GI.MultiPolygon(GI.Polygon{true,false}(lr))
            Shapefile.write(path, mp; force=true)
            g = only(Shapefile.Table(path).geometry)
            @test g isa Shapefile.PolygonZ
            @test g.zvalues == [0.04, 0.05, 0.06, 0.04, 0.04]
            @test g.measures == fill(nodata, 5)
        end
    end
end

end # module
