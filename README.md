
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

[gameprogrammingpatterns.com](https://www.gameprogrammingpatterns.com/game-loop.html)
defines a game loop as follows:

    A game loop runs continuously during gameplay. Each turn of the loop, it 
    processes user input without blocking, updates the game state, and renders 
    the game. It tracks the passage of time to control the rate of gameplay.

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

## What’s needed for a successful event loop for games? (And how do we achieve them in R?)

-   Fast display - draw quickly
-   non-blocking events
-   do game processing while idle
-   low overhead drawing device i.e. no state kept in the drawing buffer
    that needs to be managed, added to, freed etc
-   double buffering
-   FPS control
-   Fast code!
-   Global State

## Events supported by R graphics devices

-   Include a table here comparing the capabilities of quartz(),
    windows() and x11(). Also Rstudio device. i.e.
    -   keyboard events?
    -   mouse events?
    -   on idle?
    -   general speed of rendering?

## canGenOnIdle is the key

-   Have the computer run a function while waiting for input!

## Devices and ‘displaylists’

-   What are displaylists? Capture a list of all rendering commands
-   Most often seen when re-sizing a window - display list gets re-run.
-   See the effect of displaylists if we turn them off and try some of
    our usual things
-   When rendering at 30fps for a long time, that’s going to be a lot of
    junk in the displaylist that you never ever need.
-   how to turn it off

## Double buffering

-   Screen tearing
-   idle func can run much faster than the display can update!
-   weird mismatch means tearing as the screen is only partially drawn
    by R when the display system wants to put something on the screen!
-   Can probably capture this from a live screen in a gif?
-   x11 type = dbcairo
-   dev.hold()/dev.flush() (thanks to Michael Sumner for the tip)

## FPS governor

If we let the idle loop run as fast as possible, it’s possibly gonig to
run too fast!

Greeblies/enemy spaceships updating at 100 times a second could get
difficult to update in a consistent manner.

So put a governor on the FPS to try and only run our core function at
30fps (or whatever).

If it runs slower than 30fps, then there’s no need to try and limit the
speed.

If it runs faster than 30fps, then introduce little pauses each loop to
control the overall rate.

Problem: you can’t use `Sys.sleep()` in an event loop!

Solution: short bit of code to sleep for a bit.

## Fast code

-   Say ‘no’ to nested for loops.
-   Vectorize vectorize vectorize!

## Global State

-   The graphics device is a dumb canvas that gets cleared and drawn
    every frame.
-   R functions don’t have any idea of C’s static variables
-   For user functions, store global variables in the outer code.
-   For framework variables, theses are injected into the function
    environment prior to each call.
    -   Probably a better way to do this sanely, but it works OK for now
        (This was almost the title for this talk)

## Examples

-   Starfield
-   Game of life
-   Asteroids
-   raycaster engine

## Issues

-   Only the real `x11()` device on a unix or macOS system has the
    `onIdle` mechanism to make this work.
-   Sometimes the device gets locked in a slow state on macOS. I am
    unsure on why this happens, but when it does I need to
    logout-then-login to return to the high-speed state.

## Future

-   Campaign for `onIdle` to be added to `windows()` devices
-   Add mouse, keyboard event handlers to `quartz()`. Or need to start a
    new device? Some feeling is that this uses quite legacy interfaces
    that are rock solid and tested.
    -   But how do we access the fast graphics available in modern macs?

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

## Related Software

## Acknowledgements

-   R Core for developing and maintaining the language.
-   CRAN maintainers, for patiently shepherding packages onto CRAN and
    maintaining the repository
