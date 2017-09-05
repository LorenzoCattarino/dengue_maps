mean_across_fits <- function(dat) {
  
  out_names <- c("mean", "sd", "lCI", "uCI")
  
  #fl_nm <- paste0(var_names[i], ".rds")
  
  #fl <- readRDS(file.path(fl_pth, fl_nm))
  
  # check if there is only one record in the dataset
  
  if(is.null(dim(dat))) {
    
    mean_val <- mean(dat)
    
    st_dev <- sd(dat)
      
    percentiles <- quantile(dat, probs = c(0.025, 0.975))
    
    l_b <- percentiles[1]
    u_b <- percentiles[2]
      
  } else {
    
    mean_val <- rowMeans(dat)
    
    st_dev <- apply(dat, 1, FUN = sd)
    
    percentiles <- apply(dat, 1, FUN = quantile, probs = c(0.025, 0.975))
    
    percentiles <- t(percentiles)
    
    l_b <- percentiles[, 1]
    u_b <- percentiles[, 2]
    
  }
  
  setNames(data.frame(mean_val, st_dev, l_b, u_b), out_names)

}
