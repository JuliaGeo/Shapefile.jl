module ShapefileZipFileExt
import ZipFile, Shapefile
import Shapefile: _read_shp_from_zipfile, _is_zipfiles_loaded

_is_zipfiles_loaded() = true

function _read_shp_from_zipfile(zipfile)
  r = ZipFile.Reader(zipfile)
  # need to get dbx
  shpdata, shxdata, dbfdata, prjdata = nothing, nothing, nothing, nothing
  for f in r.files
    fn = f.name
    lfn = lowercase(fn)
    if endswith(lfn, ".shp")
      shpdata = IOBuffer(read(f))
    elseif endswith(lfn, ".shx")
      shxdata = read(f, Shapefile.IndexHandle)
    elseif endswith(lfn, ".dbf")
      dbfdata = Shapefile.DBFTables.Table(IOBuffer(read(f)))
    elseif endswith(lfn, "prj")
      prjdata = try
        Shapefile.GeoFormatTypes.ESRIWellKnownText(Shapefile.GeoFormatTypes.CRS(), read(f, String))
      catch
        @warn "Projection file $zipfile/$lfn appears to be corrupted. `nothing` used for `crs`"
        nothing 
      end
    end
  end
  close(r)
  @assert shpdata !== nothing
  shp = if shxdata !== nothing # we have shxdata/index 
    read(shpdata, Shapefile.Handle, shxdata)
  else
    read(shpdata, Shapefile.Handle)
  end 
  if prjdata !== nothing
    shp.crs = prjdata 
  end 
  return Shapefile.Table(shp, dbfdata)
end 

end