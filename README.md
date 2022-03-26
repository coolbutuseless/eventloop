
<!-- README.md is generated from README.Rmd. Please edit that file -->

# eventloop <img src="man/figures/eventloop-logo.png" align="right" width="230"/>

<!-- badges: start -->

![](https://img.shields.io/badge/cool-useless-green.svg)
<!-- badges: end -->

`eventloop` provides a framework for rendering interactive events to an
R graphics device at speeds fast enough to be considered interesting for
games and other ‘realtime’ animated possiblilities.

### NOTE: MacOS `xquartz/x11` and \*nix `x11()` devices only

Only the `x11` device on macOS and \*nix platforms includes an
`onIdle()` event callback which is necessary for `eventloop` to work.

## ToDo before release:

-   Introductory vignettes
    -   Overall concept
-   Tidy Vignettes
    -   Consistent documentation across all examples. i.e. same headings
-   New vignettes:
    -   Using an R6 object to manage the state rathen than having global
        vars
-   Standard note on why the vignettes only link to mp4
    -   Since an interactive app can’t be captured within a vignette, a
        video screen capture has been included with this vignette.
-   Be able to set the initial canvas colour
-   Throw an error if system == windows “Windows does not support a
    device with an ‘onIdle’ callback which is necessary to use the
    eventloop package”

``` r
# install.package('remotes')
remotes::install_github('coolbutuseless/eventloop')
```

## Example - Basic Drawing app

The following is a basic interactive example.

``` eval
library(grid)
library(eventloop)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set up the global variables which store the state of the world
#  'drawing'  Currently drawing?
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
drawing <- FALSE
last_x  <- NA
last_y  <- NA

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The main 'draw' function - his function is called repeatedly within the eventloop.
#
# If 'event' is not NULL, then it means that the user interacted with the
# display.  The following events have an effect on the canvas:
#  - hold mouse to set drawing mode
#  - releasing the mouse button stops drawing mode
#  - pressing SPACE clears the canvas
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
draw <- function(event, mouse_x, mouse_y, ...) {
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Process events
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (!is.null(event)) {
    if (event$type == 'mouse_down') {
      drawing <<- TRUE
    } else if (event$type == 'mouse_up') {
      drawing <<- FALSE
      last_x  <<- NA
      last_y  <<- NA
    } else if (event$type == 'key_press' && event$char == ' ') {
      grid::grid.rect(gp = gpar(col=NA, fill='white')) # clear screen
    }
  }
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # If 'drawing' is currently TRUE, then draw a line from last known 
  # coordinates to current mouse coordinates
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (drawing) {
    if (!is.na(last_x)) {
      grid::grid.lines(
        x = c(last_x, mouse_x),
        y = c(last_y, mouse_y),
        gp = gpar(col = 'black')
      )
    }
    
    # Keep track of where the mouse was for the next time we draw
    last_x <<- mouse_x
    last_y <<- mouse_y
  }
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Start the event loop.  
# Press ESC to quit
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
message("Hold mouse button to draw.")
message("Press space to clear canvas.")
message("Press ESC to quit.")
eventloop::run_loop(draw, fps_target = NA, double_buffer = TRUE)
```

<img src="man/figures/hello-r.gif" />

## Example - Raycaster

If your code can run fast enough in R, then you can do some more complex
rendering.

Here’s a simple raycaster in plain R.

See
[vignette](https://coolbutuseless.github.io/package/eventloop/articles/raycaster.html)
for code for this example.

<img src="man/figures/raycaster.gif" />

## Related Software

## Acknowledgements

-   R Core for developing and maintaining the language.
-   CRAN maintainers, for patiently shepherding packages onto CRAN and
    maintaining the repository
