clean_and_resample <- function(
  dat, env_vars, 
  grid_size, grp_flds) {
  
  #browser()
  
  dat[, env_vars][dat[, env_vars] == 0] <- NA
  
  xx <- remove_NA_rows(dat, env_vars)
  
  bb <- xx[!is.na(xx$population), ]
  
  if (nrow(bb) > 0) {
    
    bb[bb$population == 0, "population"] <- 1
    
  }
  
  yy <- grid_up(
    dataset = bb, 
    grid_size = grid_size, 
    rnd_dist = FALSE)
  
  average_up(yy, grp_flds, env_vars)
  
}