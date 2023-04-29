const Shape = Union{AbstractShape,LinearRing{Point},SubPolygon{<:LinearRing{Point}}}
const ShapeZ = Union{PolylineZ,PolygonZ,MultiPointZ,MultiPatch,LinearRing{PointZ},SubPolygon{<:LinearRing{PointZ}}}
const ShapeM = Union{PolylineM,PolygonM,MultiPointM,LinearRing{PointM},SubPolygon{<:LinearRing{PointM}}}

# 3d
GI.is3d(::GI.AbstractGeometryTrait, ::Union{Shape,ShapeM}) = false
GI.is3d(::GI.AbstractPointTrait, ::Union{Point,PointM}) = false
GI.is3d(::GI.AbstractGeometryTrait, ::ShapeZ) = true
GI.is3d(::GI.AbstractPointTrait, ::PointZ) = true

# measured
GI.ismeasured(::GI.AbstractGeometryTrait, ::Shape) = false
GI.ismeasured(::GI.AbstractPointTrait, ::Point) = false
GI.ismeasured(::GI.AbstractGeometryTrait, ::Union{ShapeM,ShapeZ}) = true
GI.ismeasured(::GI.AbstractPointTrait, ::Union{PointM,PointZ}) = true

GI.coordnames(t::GI.AbstractGeometryTrait, geom::Union{Point,Shape}) = (:X, :Y)
GI.coordnames(t::GI.AbstractGeometryTrait, geom::Union{PointM,ShapeM}) = (:X, :Y, :M)
GI.coordnames(t::GI.AbstractGeometryTrait, geom::Union{PointZ,ShapeZ}) = (:X, :Y, :Z, :M)

# extent
# Sub geometries have no known extent
GI.extent(::GI.LinearRingTrait, p::LinearRing) = nothing
GI.extent(::GI.PolygonTrait, p::SubPolygon) = nothing
# Other geoms have precalculated extent
GI.extent(::GI.PointTrait, p::Union{Point,PointM}) =
    Extents.Extent(X=(p.x, p.x), Y=(p.y, p.y))
GI.extent(::GI.PointTrait, p::PointZ) =
    Extents.Extent(X=(p.x, p.x), Y=(p.y, p.y), Z=(p.z, p.z))
function GI.extent(::GI.AbstractGeometryTrait, x::AbstractShape)
    rect = x.MBR
    return Extents.Extent(X=(rect.left, rect.right), Y=(rect.bottom, rect.top))
end
function GI.extent(::GI.AbstractGeometryTrait, x::ShapeZ)
    rect = x.MBR
    return Extents.Extent(X=(rect.left, rect.right), Y=(rect.bottom, rect.top), Z=(x.zrange.left, x.zrange.right))
end
GI.extent(x::Handle) = GI.extent(x.header)
function GI.extent(x::Header)
    rect = x.MBR
    return Extents.Extent(X=(rect.left, rect.right), Y=(rect.bottom, rect.top), Z=(x.zrange.left, x.zrange.right))
end
