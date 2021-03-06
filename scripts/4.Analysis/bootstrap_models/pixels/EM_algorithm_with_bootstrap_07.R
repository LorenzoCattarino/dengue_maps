# For each bootstrap sample of the original dataset, it creates a scatter plot of:  
#
# 1) admin unit observation vs admin unit prediction 
# 2) admin unit observation vs population weighted average of the square predictions (within admin unit)
# 3) admin unit observation vs population weighted average of the 1 km pixel predictions (within admin unit)
#
# NOTE: 1, 2 and 3 are for train and test sets separately (total of 6 plots per bootstrap sample)

library(reshape2)
library(ggplot2)
library(plyr)
library(weights) # for wtd.cor()

source(file.path("R", "utility_functions.R"))
source(file.path("R", "create_parameter_list.R"))
source(file.path("R", "plotting", "plot_RF_preds_vs_obs_by_cv_dataset.R"))
source(file.path("R", "prepare_datasets", "set_pseudo_abs_weights.R"))
source(file.path("R", "prepare_datasets", "calculate_sd.R"))
source(file.path("R", "prepare_datasets", "calculate_wgt_corr.R"))


# define parameters -----------------------------------------------------------  


extra_prms <- list(id = 2,
                   dependent_variable = "FOI") 

mes_vars <- c("admin", "mean_p_i")

tags <- c("all_data", "no_psAb")

data_types_vec <- list(c("serology", "caseReport", "pseudoAbsence"),
                       c("serology", "caseReport"))


# define variables ------------------------------------------------------------


parameters <- create_parameter_list(extra_params = extra_prms)

model_type <- paste0("model_", parameters$id)

var_to_fit <- parameters$dependent_variable

psAbs_val <- parameters$pseudoAbs_value[var_to_fit]

in_path <- file.path("output",
                     "EM_algorithm",
                     "bootstrap_models",
                     model_type,
                     "adm_foi_predictions") 

out_fig_path <- file.path("figures",
                          "EM_algorithm",
                          "bootstrap_models",
                          model_type,
                          "scatter_plots",
                          "boot_samples")

out_fig_path_av <- file.path("figures",
                             "EM_algorithm",
                             "bootstrap_models",
                             model_type,
                             "scatter_plots")

out_table_path <- file.path("output",
                            "EM_algorithm",
                            "bootstrap_models",
                            model_type,
                            "scatter_plots")


# pre processing --------------------------------------------------------------


fi <- list.files(in_path, pattern = ".*.rds", full.names = TRUE)

all_pred_tables <- EM_alg_run <- lapply(fi, readRDS) 

foi_dataset <- all_pred_tables[[1]]

no_samples <- parameters$no_samples

no_datapoints <- nrow(foi_dataset)

no_pseudoAbs <- sum(foi_dataset$type == "pseudoAbsence") 

no_pnts_vec <- c(no_datapoints, no_datapoints - no_pseudoAbs) 


# start ----------------------------------------------------------------------- 


for (j in seq_along(tags)) {
  
  no_pnts <- no_pnts_vec[j]
  
  dt_typ <- data_types_vec[[j]]
  
  tag <- tags[j]
  
  
  #### create objects for matrix algebric operations
  
  
  all_adm_preds <- matrix(0, nrow = no_pnts, ncol = no_samples)
  all_sqr_preds <- matrix(0, nrow = no_pnts, ncol = no_samples)
  train_ids <- matrix(0, nrow = no_pnts, ncol = no_samples)
  test_ids <- matrix(0, nrow = no_pnts, ncol = no_samples)
  
  
  #### second loop
  
  
  for (i in seq_len(no_samples)) {
    
    dts_1 <- all_pred_tables[[i]]
    
    if(var_to_fit == "FOI"){
      
      dts_1[, c("o_j", "admin", "mean_p_i")][dts_1[, c("o_j", "admin", "mean_p_i")] < 0] <- 0
      
    } else {
      
      dts_1[, c("o_j", "admin", "mean_p_i")][dts_1[, c("o_j", "admin", "mean_p_i")] < 1] <- psAbs_val
      
    }
    
    dts <- dts_1[dts_1$type %in% dt_typ, ]
    
    
    #####
    
    all_adm_preds[,i] <- dts$admin
    all_sqr_preds[,i] <- dts$mean_p_i
    train_ids[,i] <- dts$train
    test_ids[,i] <- 1 - dts$train
    
    #####
    
    
    names(dts)[names(dts) == "train"] <- "dataset"
    
    dts$dataset <- factor(x = dts$dataset, levels = c(1, 0), labels = c("train", "test"))
    
  }
  
  
  #### calculate the mean across fits of the predictions (adm, sqr and pxl) 
  #### by train and test dataset separately
  
  
  train_sets_n <- rowSums(train_ids)
  test_sets_n <- rowSums(test_ids)
  
  mean_adm_pred_train <- rowSums(all_adm_preds * train_ids) / train_sets_n
  mean_adm_pred_test <- rowSums(all_adm_preds * test_ids) / test_sets_n
  
  mean_sqr_pred_train <- rowSums(all_sqr_preds * train_ids) / train_sets_n
  mean_sqr_pred_test <- rowSums(all_sqr_preds * test_ids) / test_sets_n
  
  sd_mean_adm_pred_train <- vapply(seq_len(no_pnts), calculate_sd, 1, all_adm_preds, train_ids)
  sd_mean_adm_pred_test <- vapply(seq_len(no_pnts), calculate_sd, 1, all_adm_preds, test_ids)
  
  sd_mean_sqr_pred_train <- vapply(seq_len(no_pnts), calculate_sd, 1, all_sqr_preds, train_ids)
  sd_mean_sqr_pred_test <- vapply(seq_len(no_pnts), calculate_sd, 1, all_sqr_preds, test_ids)
  
  av_train_preds <- data.frame(dts[,c("data_id", "ID_0", "ID_1", "o_j", "new_weight")],
                               admin = mean_adm_pred_train,
                               mean_p_i = mean_sqr_pred_train,
                               admin_sd = sd_mean_adm_pred_train,
                               cell_sd = sd_mean_sqr_pred_train,
                               dataset = "train")
  
  av_test_preds <- data.frame(dts[,c("data_id", "ID_0", "ID_1", "o_j", "new_weight")],
                              admin = mean_adm_pred_test,
                              mean_p_i = mean_sqr_pred_test,
                              admin_sd = sd_mean_adm_pred_test,
                              cell_sd = sd_mean_sqr_pred_test,
                              dataset = "test")
  
  all_av_preds <- rbind(av_train_preds, av_test_preds)
  write_out_csv(all_av_preds, out_table_path, paste0("pred_vs_obs_plot_averages_", tag, ".csv"), row.names = FALSE)
  
  ret <- melt(
    all_av_preds,
    id.vars = c("data_id", "ID_0", "ID_1", "o_j", "dataset", "new_weight"),
    measure.vars = mes_vars,
    variable.name = "scale")
  
  fl_nm_av <- paste0("pred_vs_obs_plot_averages_", tag, ".png")
  
  RF_preds_vs_obs_plot_stratif(df = ret,
                               x = "o_j",
                               y = "value",
                               facet_var = "scale",
                               file_name = fl_nm_av,
                               file_path = out_fig_path_av)
  
}
