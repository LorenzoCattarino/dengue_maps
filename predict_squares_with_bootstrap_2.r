# Load back square predictions for the world, for each model fit 
# Save a n squares x n fits matrix. 

options(didehpc.cluster = "fi--didemrchnb")

CLUSTER <- TRUE

my_resources <- c(
  file.path("R", "random_forest", "fit_h2o_RF_and_make_predictions.R"),
  file.path("R", "utility_functions.R"))

my_pkgs <- "h2o"

context::context_log_start()
ctx <- context::context_save(path = "context",
                             packages = my_pkgs,
                             sources = my_resources)


# define parameters ----------------------------------------------------------- 


parameters <- list(
  dependent_variable = "FOI",
  grid_size = 0.5,
  no_samples = 200,
  no_predictors = 9)   

out_fl_nm <- "response.rds"


# define variables ------------------------------------------------------------


model_type <- paste0(parameters$dependent_variable, "_boot_model")

my_dir <- paste0("grid_size_", parameters$grid_size)

out_pt <- file.path("output", 
                    "predictions_world", 
                    "bootstrap_models",
                    my_dir,
                    model_type)


# rebuild the queue object? --------------------------------------------------- 


if (CLUSTER) {
  
  config <- didehpc::didehpc_config(template = "20Core")
  obj <- didehpc::queue_didehpc(ctx, config = config)
  
} else {
  
  context::context_load(ctx)
  
}


# get results ----------------------------------------------------------------- 


# loads the LAST task bundle
my_task_id <- obj$task_bundle_info()[nrow(obj$task_bundle_info()), "name"] 

sqr_preds_boot_t <- obj$task_bundle_get(my_task_id)

sqr_preds_boot <- sqr_preds_boot_t$results()


# combine all results together ------------------------------------------------ 


sqr_preds <- do.call("cbind", sqr_preds_boot)

write_out_rds(sqr_preds, out_pt, out_fl_nm)  
