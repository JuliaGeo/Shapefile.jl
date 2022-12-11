const ShapeZ = Union{PolylineZ,PolygonZ,MultiPointZ,MultiPatch}
const ShapeM = Union{ShapeZ,PolylineM,PolygonM,MultiPointM}

# 3d
GI.is3d(::GI.AbstractGeometryTrait, ::AbstractShape) = false
GI.is3d(::GI.AbstractPointTrait, ::AbstractPoint) = false
GI.is3d(::GI.AbstractGeometryTrait, ::ShapeZ) = true
GI.is3d(::GI.AbstractPointTrait, ::PointZ) = true

# measured
GI.ismeasured(::GI.AbstractGeometryTrait, ::AbstractShape) = false
GI.ismeasured(::GI.AbstractGeometryTrait, ::ShapeM) = true
GI.ismeasured(::GI.AbstractPointTrait, ::Point) = false
GI.ismeasured(::GI.AbstractPointTrait, ::Union{PointM,PointZ}) = true

# extent
function GI.extent(x::AbstractShape)
    rect = x.MBR
    return Extents.Extent(X=(rect.left, rect.right), Y=(rect.bottom, rect.top))
end
GI.extent(x::Handle) = GI.extent(x.header)
function GI.extent(x::Union{ShapeZ,Header})
    rect = x.MBR
    return Extents.Extent(X=(rect.left, rect.right), Y=(rect.bottom, rect.top), Z=(x.zrange.left, x.zrange.right))
end
