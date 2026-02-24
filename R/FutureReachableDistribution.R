# R/functions-future_reachable.R

#' Process one species binary map into FuturePotentialReachable raster
process_one_species_future_reachable <- function(sp,
                                                 conh_files,
                                                 conh_dir,
                                                 out_dir) {
  sp_name <- gsub("^binary_|\\.tif$", "", basename(sp))
  print(paste("Now running:", sp_name))
  # # Load inside worker (good for clustermq R workers)
  # suppressPackageStartupMessages(library(terra))
  # 
  # # Node-local temp if available; otherwise fallback
  # tmpdir <- Sys.getenv("SLURM_TMPDIR", unset = tempdir())
  # dir.create(tmpdir, recursive = TRUE, showWarnings = FALSE)
  # 
  # # Conservative threading + quiet logs
  # terraOptions(tempdir = tmpdir, progress = 0, threads = 1)
  # Sys.setenv(GDAL_NUM_THREADS = "1")
  
  # Ensure output dir exists (safe under parallel calls)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Start processing species binary maps.
  
  conh_path <- paste0(conh_dir, sp_name, "_ConvexHullBuffer.shp")
  # if (!file.exists(conh_path)) {
  #   return(list(species = sp_name, ok = FALSE, msg = "Convex hull not found", out = NA_character_))
  # }
  
  out_file <- paste0(out_dir, sp_name, "_FuturePotentialReachable.tif")
  if (file.exists(out_file)) {
    return(list(species = sp_name, ok = TRUE, msg = "Output already exists (skipped)", out = out_file))
  }
  
  conh_poly <- terra::vect(conh_path)
  bin_rast  <- terra::rast(sp)
  
  # # Outside hull -> 0; original NA stays NA (updateNA defaults to FALSE)
  # actual_dist02 <- terra::mask(
  #   x = bin_rast,
  #   mask = conh_poly,
  #   inverse = TRUE,
  #   updatevalue = 0
  # )
  
  # original NA mask
  orig_na <- is.na(bin_rast)
  
  # mask within hull
  actual_dist <- mask(bin_rast, conh_poly)
  
  # outside hull -> 0
  zero_raster <- actual_dist
  values(zero_raster) <- 0
  actual_dist02 <- cover(actual_dist, zero_raster)
  
  # restore original NA everywhere
  actual_dist02[orig_na] <- NA
  terra::writeRaster(actual_dist02, out_file, overwrite = TRUE)
  
  rm(conh_poly, bin_rast, actual_dist02)
  gc()
  
  list(species = sp_name, ok = TRUE, msg = "saved", out = out_file)
}