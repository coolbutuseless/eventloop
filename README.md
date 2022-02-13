
<!-- README.md is generated from README.Rmd. Please edit that file -->

# eventloop

<!-- badges: start -->

![](https://img.shields.io/badge/cool-useless-green.svg)
<!-- badges: end -->

The goal of eventloop is to …

## Installation

You can install from
[GitHub](https://github.com/coolbutuseless/eventloop) with:

``` r
# install.package('remotes')
remotes::install_github('coolbutuseless/eventloop')
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(eventloop)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
colours <- rainbow(100)
latch   <- FALSE

colour_cycle <- function() {
  if (!is.null(event)) {
    if (event$type == 'click') {
      latch <<- TRUE
      msg <- sprintf("(%.1f, %.1f) (%.1f, %.1f), (%f, %f) %.1f", x, y, X, Y, width, height, fps)
      cat(msg, "\n")
    } else if (event$type == 'release') {
      latch <<- FALSE
    }
  }

  if (latch) {
    col <- colours[[(frame %% 100) + 1L]]
  } else {
    col <- 'white'
  }

  grid::grid.rect(gp = grid::gpar(fill = col))
  grid::grid.text(label = paste("FPS: ", round(fps)), x = 0.01, y = 0.01, just = c('left', 'bottom'),
                  gp = grid::gpar(fontfamily = 'mono', cex = 2))
}


run_loop(colour_cycle, 7, 7)
```

## Related Software

## Acknowledgements

-   R Core for developing and maintaining the language.
-   CRAN maintainers, for patiently shepherding packages onto CRAN and
    maintaining the repository
