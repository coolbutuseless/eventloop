## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
N <- 9
mat <- matrix(seq(N*N), N, N)

## ----setup--------------------------------------------------------------------
library(eventloop)
library(ggplot2)
library(dplyr)
library(purrr)
library(grid)
library(magrittr)

N <- 9
set.seed(1)
mat <- matrix(sample(c(0, 1), N*N, replace = TRUE, prob = c(0.85, 0.3)), N, N)
mat[1,] <- 1
mat[N,] <- 1
mat[,1] <- 1
mat[,N] <- 1
# mat <- matrix(seq(N*N), N, N)

df <- expand.grid(y = seq(N)-0.5, x = seq(N)-0.5)
df$val <- as.vector(mat)
df$col <- ifelse(df$val == 1, 'grey70', 'white')



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Cast a ray in the given direction
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
raycast <- function(x0, y0, direction) {
  
  theta <- direction * pi/180
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Horizontal intercepts
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  yfrac <- 1 - (y0 - floor(y0))
  
  dx <- 1/tan(theta)
  if (theta > 0 && theta < pi) {
    dy <- 1
  } else {
    dy <- -1
    yfrac <- (y0 - floor(y0))
  }
  
  if (theta > pi) {
    dx <- -dx
  }
  
  hor <- data.frame(
    x = x0 + yfrac * dx + seq.int(0, 4) * dx,
    y = y0 + yfrac * dy + seq.int(0, 4) * dy
  )
  
  hor %<>%
    filter(x > 0, x < N, y > 0, y < N)
  
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Vertical intercepts
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  xfrac <- 1 - (x0 - floor(x0))
  
  dy <-   tan(theta)
  if (theta > 3*pi/2 || theta < pi/2) {
    dx <- 1
  } else {
    dx <- -1
    xfrac <- x0 - floor(x0)
  }
  
  if (theta > pi/2 && theta < 3*pi/2) {
    dy <- -dy
  }
  
  ver <- data.frame(
    x = x0 + xfrac * dx + seq.int(0, 4) * dx,
    y = y0 + xfrac * dy + seq.int(0, 4) * dy
  )
  
  
  ver %<>%
    filter(x > 0, x < N, y > 0, y < N)
  
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Search for "1"s in the matrix along each of the probes for 
  # vertical and horizontal intersection
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Quadrant 1
  if (theta >= 0 && theta <= pi/2) {
    hhits <- mat[cbind(hor$y + 1, ceiling(hor$x))]
    vhits <- mat[cbind(ceiling(ver$y), ver$x + 1)]
  } else if (theta > pi/2 && theta <= pi) {
    # Quadrant 2
    hhits <- mat[cbind(hor$y + 1, ceiling(hor$x))]
    vhits <- mat[cbind(ceiling(ver$y), ver$x)]
  } else if (theta > pi && theta <= 3*pi/2) {
    # Quadrant 3
    hhits <- mat[cbind(hor$y, ceiling(hor$x))]
    vhits <- mat[cbind(ceiling(ver$y), ver$x)]
  } else if (theta > 3*pi/2 && theta <= 2*pi) {
    # Quadrant 4
    hhits <- mat[cbind(hor$y, ceiling(hor$x))]
    vhits <- mat[cbind(ceiling(ver$y), ver$x + 1)]
  } else {
    stop("Bad quadrant")
  }
  
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Find the minimum distance intersection and return that distance
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  hfirst <- which.max(hhits)
  vfirst <- which.max(vhits)
  
  hbest <- hor[hfirst,]
  vbest <- ver[vfirst,]
  
  if (max(hhits) == 0) {
    dist <- sqrt((vbest$x - x0)^2 + (vbest$y - y0)^2)
  } else if (max(vhits) == 0) {
    dist <- sqrt((hbest$x - x0)^2 + (hbest$y - y0)^2)
  } else {
    hdist <- sqrt((hbest$x - x0)^2 + (hbest$y - y0)^2)
    vdist <- sqrt((vbest$x - x0)^2 + (vbest$y - y0)^2)
    
    dist <- min(hdist, vdist)
  }
  
  dist
}


x0 <- 4.7
y0 <- 3.4
Nrays <- 30
angles <- seq(15, 60, length.out = Nrays)
thetas <- angles * pi/180

dists0 <- purrr::map_dbl(angles, ~raycast(x0, y0, .x))

# fisheye correction
dists <- dists0 * cos(thetas)

heights <- 0.75 * 1/dists0



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Plot the DDA view
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dunit <- 'cm'

grid.rect(gp = gpar(fill='white'))

grid.rect(
  x      = ((Nrays:1)-0.5)/Nrays, 
  width  = 1/Nrays, 
  height = heights,
  gp     = gpar(col=NA, fill='darkblue')
)
  


grid.rect(x = df$x, y = df$y, width = 1, height = 1, default.units = dunit,
          gp = gpar(fill = df$col, col = 'grey50', alpha = 0.5))
# grid.text(df$val,df$x, df$y, default.units = dunit, gp = gpar(col = 'grey40'))
grid.points(x0, y0, default.units = dunit)

# Intersection ray
xh <- x0 + dists0 * cos(thetas)
yh <- y0 + dists0 * sin(thetas)
grid.polyline(
  x = c(rbind(x0, xh)), 
  y = c(rbind(y0, yh)), 
  default.units = dunit,
  gp = gpar(
    col   = 'darkgreen', 
    lwd   = 1, 
    alpha = 0.5
  ), 
  id = rep(seq(Nrays), each = 2)
)

