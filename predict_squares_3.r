# Makes a map of the square predictions

options(didehpc.cluster = "fi--didemrchnb")

CLUSTER <- FALSE

my_resources <- c(
  file.path("R", "plotting", "functions_for_plotting_raster_maps.R"),
  file.path("R", "utility_functions.R"))

my_pkgs <- c("data.table", "ggplot2", "fields", "rgdal", "scales", "RColorBrewer", "colorRamps")

context::context_log_start()
ctx <- context::context_save(path = "context",
                             sources = my_resources,
                             packages = my_pkgs)


# define parameters ----------------------------------------------------------- 


parameters <- list(
  dependent_variable = "R0_3")   

vars_to_average <- "response"

statistic <- "best"

model_id <- 12

n_col <- 100

FOI_z_range <- c(0, 0.06)
R0_1_z_range <- c(0, 8)
R0_2_z_range <- c(0, 4)
R0_3_z_range <- c(0, 5)

z_range <- R0_3_z_range


# define variables ------------------------------------------------------------


model_type <- paste0("model_", model_id)

in_path <- file.path("output", 
                     "predictions_world", 
                     "best_fit_models",
                     model_type)

out_path <- file.path("figures", 
                      "predictions_world",
                      "best_fit_models",
                      model_type)


# are you using the cluster? -------------------------------------------------- 


if (CLUSTER) {
  
  obj <- didehpc::queue_didehpc(ctx)
  
} else {
  
  context::context_load(ctx)

}


# pre processing -------------------------------------------------------------- 


my_col <- matlab.like(n_col)

mean_pred_fl_nm <- paste0(vars_to_average, ".rds")

df_long <- readRDS(file.path(in_path, mean_pred_fl_nm))

out_fl_nm <- paste0(vars_to_average, "_", statistic, ".png")


# plot ------------------------------------------------------------------------ 


quick_raster_map(pred_df = df_long, 
                 variable = vars_to_average, 
                 statistic = statistic, 
                 my_col = my_col, 
                 out_pt = out_path, 
                 out_name = out_fl_nm,
                 z_range = z_range)

