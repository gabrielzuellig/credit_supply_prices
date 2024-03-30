weighted_cdf <- function(x, w, name){
  
  library(data.table)
  
  df <- data.frame(x=x, weight=w)   # combine data vectors
  df <- df[!is.na(df$x), ]  # get rid of NA's in x
  df$w <- df$w / sum(df$w) # re-compute weights to sum to 1 
  dfsorted <- df[order(df$x), ] # sort
  dfsorted$cumfreq <- cumsum(dfsorted$w) / sum(dfsorted$w)
  dfsorted2 <- dfsorted[rep(1:nrow(df), each=2),]
  dfsorted2$cumfreq <- c(0,dfsorted2$cumfreq[-2*nrow(df)])
  dfsorted2 <- data.table(dfsorted2)
  dfsorted2 <- data.frame(dfsorted2[, j=list(cdf=max(cumfreq)), by=list(x)])
  dfsorted2 <- rbind(c(1, 0), dfsorted2)
  plot(dfsorted2$x, dfsorted2$cdf, type="s")
  colnames(dfsorted2)[2] <- paste0(colnames(dfsorted2)[2], '_', name)
  return(dfsorted2)
  
}