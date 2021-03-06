# Creates a set of bootstrap samples 

options(didehpc.cluster = "fi--didemrchnb")

my_resources <- c(
  file.path("R", "prepare_datasets", "functions_for_creating_bootstrap_samples.R"),
  file.path("R", "prepare_datasets", "set_pseudo_abs_weights.R"),
  file.path("R", "prepare_datasets", "grid_up.R"),
  file.path("R", "utility_functions.R"),
  file.path("R", "create_parameter_list.R"))

context::context_log_start()
ctx <- context::context_save(path = "context",
                             sources = my_resources)

context::context_load(ctx)
context::parallel_cluster_start(8, ctx)


# define parameters ----------------------------------------------------------- 


out_fl_nm <- "bootstrap_samples.rds"


# define variables ------------------------------------------------------------


parameters <- create_parameter_list()

grid_size <- parameters$grid_size

my_dir <- paste0("grid_size_", grid_size)

out_pt <- file.path("output", "EM_algorithm", "bootstrap_models", my_dir)


# load data ------------------------------------------------------------------- 


foi_data <- read.csv(file.path("output", 
                               "foi", 
                               "All_FOI_estimates_and_predictors.csv"),
                     stringsAsFactors = FALSE) 


# pre processing --------------------------------------------------------------


foi_data$new_weight <- parameters$all_wgt

pAbs_wgt <- get_sat_area_wgts(foi_data, parameters)

foi_data[foi_data$type == "pseudoAbsence", "new_weight"] <- pAbs_wgt

no_samples <- parameters$no_samples


# submit jobs ----------------------------------------------------------------- 


boot_samples <- loop(
  seq_len(no_samples),
  grid_and_boot,
  a = foi_data,
  b = parameters$grid_size,
  parallel = TRUE)


# save ------------------------------------------------------------------------ 


write_out_rds(boot_samples, out_pt, out_fl_nm)


# stop cluster ---------------------------------------------------------------- 


context::parallel_cluster_stop()
