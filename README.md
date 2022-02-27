
<!-- README.md is generated from README.Rmd. Please edit that file -->

# eventloop

<!-- badges: start -->

![](https://img.shields.io/badge/cool-useless-green.svg)
<!-- badges: end -->

`eventloop` provides a framework for rendering interactive events to an
R graphics device at speeds fast enough to be considered interesting for
games and other ‘realtime’ animated possiblilities.

An event loop (or ‘game loop’, or ‘interactive loop’) is a programming
pattern where the system processes user input, but does other duties
while waiting for that input.

When used in games, the game loop updates the world, moves spaceships,
spawns greeblies. When the user gives input (e.g. pressing the ‘jump’
button), the system handles that user input - while also taking time to
keep updating the greeblies and spaceshipts etc.

Currently ‘shiny’ may be the the most common R frameworks for
development of interactive programs. It is a powerful framework which
taps into a “reactive web application” mode of operations - which all
has a few too many layers of abstraction to be fast.

In the wider programming world, [`processing`](https://processing.org/)
is a great example of an accessible game programming loop that uses a
domain specific interaction language (built upon a Java backend).

## Installation

You can install from
[GitHub](https://github.com/coolbutuseless/eventloop) with:

``` r
# install.package('remotes')
remotes::install_github('coolbutuseless/eventloop')
```

## Example - colour cycling

The following is a basic interactive example.

When you click-and-hold the mouse button in the window, the colour will
cycle through 100 colours of the rainbox.

Releasing the mouse will halt the colour cycling

``` r
library(eventloop)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Define global variables which will maintain the state of the 'game'
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
colours <- rainbow(100)
latch   <- FALSE

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Define the operations to be performed each loop
#
#  Standard variables defined as part of rendering framework
#  - x, y         coordinates of mouse in npc i.e. range [0, 1]
#  - X, Y         mouse coordinates in pixels
#  - width,height dimensions of window in pixels
#  - fps          frames per second in last 100 frames
#  - frame        current frame number (integer sequence starting from 1)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
colour_cycle <- function() {
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # If there has been an event, then process it
  # All this code does is
  #   - set 'latch' to TRUE if a mouse button is pressed
  #   - sets 'latch' to FALSE when the mouse button is released
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (!is.null(event)) {
    if (event$type == 'click') {
      latch <<- TRUE
      msg <- sprintf("(%.1f, %.1f) (%.1f, %.1f), (%f, %f) %.1f", x, y, X, Y, width, height, fps)
      cat(msg, "\n")
    } else if (event$type == 'release') {
      latch <<- FALSE
    }
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # If the 'latch' is on then choose a colour based upon the current frame number
  # otherwise set colour to white
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (latch) {
    col <- colours[[(frame %% 100) + 1L]]
  } else {
    col <- 'white'
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Fill the screen with the current colour
  # Draw an FPS counter
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  grid::grid.rect(gp = grid::gpar(fill = col))
  grid::grid.text(
    label = paste("FPS: ", round(fps)), x = 0.01, y = 0.01, just = c('left', 'bottom'),
    gp = grid::gpar(fontfamily = 'mono', cex = 2)
  )
}


run_loop(colour_cycle, 7, 7)
```

## Issues

-   Only the real `x11()` device on a unix or macOS system has the
    `onIdle` mechanism to make this work.
-   Sometimes the device gets locked in a slow state on macOS. I am
    unsure on why this happens, but when it does I need to
    logout-then-login to return to the high-speed state.

## Future

-   Campaign for `onIdle` to be added to `quartz()` and `windows()`
    devices
-   Add mouse and keyboard event handles to `quartz()`. Or need to start
    a new device?

## Related Software

## Acknowledgements

-   R Core for developing and maintaining the language.
-   CRAN maintainers, for patiently shepherding packages onto CRAN and
    maintaining the repository
