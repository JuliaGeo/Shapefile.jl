module ShapefileZipArchivesExt
import ZipArchives, Shapefile
import Shapefile: _read_shp_from_ziparchive, _is_ziparchives_loaded
import Mmap # to present zip files as AbstractVector{UInt8}

_is_ziparchives_loaded() = true

function _read_shp_from_ziparchive(zipfile)
  zip_file_handler = open(zipfile)
  mmapped_zip_file = Mmap.mmap(zip_file_handler)
  r = ZipArchives.ZipReader(mmapped_zip_file)
  # need to get dbx
  shpdata, shxdata, dbfdata, prjdata = nothing, nothing, nothing, nothing
  for filename in ZipArchives.zip_names(r)
    lfn = lowercase(filename)
    if endswith(lfn, ".shp")
      shpdata = IOBuffer(ZipArchives.zip_readentry(r, filename))
    elseif endswith(lfn, ".shx")
      shxdata = ZipArchives.zip_readentry(r, filename, Shapefile.IndexHandle)
    elseif endswith(lfn, ".dbf")
      ZipArchives.zip_openentry(r, filename) do io
        dbfdata = Shapefile.DBFTables.Table(io)
      end
    elseif endswith(lfn, "prj")
      prjdata = try
        Shapefile.GeoFormatTypes.ESRIWellKnownText(Shapefile.GeoFormatTypes.CRS(), ZipArchives.zip_readentry(r, filename, String))
      catch
        @warn "Projection file $zipfile/$lfn appears to be corrupted. `nothing` used for `crs`"
        nothing 
      end
    end
  end
  
  # Finished the reading loop, we don't need the zip file anymore.

  close(zip_file_handler)
  
  # Populate the Shapefile.Table
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