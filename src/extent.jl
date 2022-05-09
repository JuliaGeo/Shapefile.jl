const Shape3D = Union{PolylineZ,PolygonZ,MultiPointZ,MultiPatch}

# extent
GI.is3d(::GI.AbstractGeometryTrait, ::AbstractShape) = false
GI.is3d(::GI.AbstractGeometryTrait, ::Shape3D) = true

function GI.extent(x::AbstractShape)
    rect = x.MBR
    return Extents.Extent(X=(rect.left, rect.right), Y=(rect.bottom, rect.top))
end
function GI.extent(x::Union{Shape3D,Handle})
    rect = x.MBR
    return Extents.Extent(X=(rect.left, rect.right), Y=(rect.bottom, rect.top), Z=(x.zrange.left, x.zrange.right))
end
