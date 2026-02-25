# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)
library(clustermq)

## Running on HPC
# Settings for clustermq
options(
  clustermq.scheduler = "slurm",
  clustermq.template = "./cmq.tmpl" # if using your own template
)

# Running locally on Windows
# options(clustermq.scheduler = "multiprocess")

## Settings for clustermq template when running clustermq on HPC
tar_option_set(
  resources = tar_resources(
    clustermq = tar_resources_clustermq(template = list(
      job_name = "future_rechable",
      per_cpu_mem = "6400mb", #"3470mb"(wice thin node), #"21000mb" (genius bigmem， hugemem)"5100mb"
      n_tasks = 2,
      per_task_cpus = 14,
      walltime = "10:00:00"
    ))
  )
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# tar_source("other_functions.R") # Source other scripts as needed.

tar_plan(
  conh_files = list.files(
    "/lustre1/scratch/348/vsc34871/input/Convexhull_Buffer/",
    full.names = T),
  conh_dir = "/lustre1/scratch/348/vsc34871/input/Convexhull_Buffer/",
  out_dir = "/lustre1/scratch/348/vsc34871/SDM_fut/results/BinaryMaps_FuturePotentialRechableDist/",
  sp = list.files(
    "/lustre1/scratch/348/vsc34871/input/BinaryMaps_original/",  pattern = "\\.tif$",
    full.names = T),

#tar_target(sp_name, gsub("^binary_|\\.tif$", "", basename(sp))),

# tar_target(convex_buffer,
#            file.path(conh_dir, paste0(sp_name, "_ConvexHullBuffer.shp")),
#            pattern = map(conh_dir)),
tar_target(future_reachable_distributions,
           process_one_species_future_reachable(
             sp,
             conh_files,
             conh_dir,
             out_dir
           ),
           pattern = map(sp),
           format = "file"
)
)

