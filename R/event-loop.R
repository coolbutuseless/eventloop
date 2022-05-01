

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mouse Down - The callback function run when a button on the mouse is pressed
#
# - The event loop will terminate as soon as this returns any non-NULL object
# - So just capture the information about the event and put it in the
#   graphics event environment
# - The onIdle callback will use this event data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onMouseDown <- function(button, x, y) {

  event_env <- grDevices::getGraphicsEventEnv()

  event_env$event <- list(
    type   = 'mouse_down',
    button = button,
    x      = x,
    y      = y
  )

  NULL
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mouse Up - The callback function run when a button on the mouse is released
#
# - The event loop will terminate as soon as this returns any non-NULL object
# - So just capture the information about the event and put it in the
#   graphics event environment
# - The onIdle callback will use this event data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onMouseUp <- function(button, x, y, ...) {

  event_env <- getGraphicsEventEnv()

  event_env$event <- list(
    type   = 'mouse_up',
    button = button,
    x      = x,
    y      = y
  )

  NULL
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mouse Move - The callback function run when the mouse is moved within the window
#
# - The event loop will terminate as soon as this returns any non-NULL object
# - So just capture the information about the event and put it in the
#   graphics event environment
# - The onIdle callback will use this event data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onMouseMove <- function(button, x, y) {

  event_env <- grDevices::getGraphicsEventEnv()

  if (is.null(event_env$event)) {
    event_env$event <- list(
      type   = 'mouse_move',
      button = button,
      x      = x,
      y      = y
    )
  }

  NULL
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Key Press - The callback function run when a key is pressed
#
# - The event loop will terminate as soon as this returns any non-NULL object
# - So just capture the information about the event and put it in the
#   graphics event environment
# - The onIdle callback will use this event data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onKeybd <- function(char) {

  event_env <- grDevices::getGraphicsEventEnv()

  event_env$event <- list(
    type = 'key_press',
    str  = char
  )

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Quit when 'ESC' pressed.
  # Quitting out of an event loop is as simple as returning a non-NULL
  # value from any of the callbacks
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (identical(utf8ToInt(char), 27L)) {
    "Quit Requested"
  } else {
    NULL
  }
}




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate an 'onIdle' callback function that wraps the users function
#
# This final onIdle callback function:
#   - interogates the graphics event environment to see if anything has happened
#   - unpacks the current (x,y) coordinates if available
#   - inserts pauses to try and slow down to the users target FPS
#   - if double buffered calls `dev.hold()`
#   - calls the users function
#   - draws the FPS on screen if this has been requested
#   - if double buffered, then calls `dev.flush()`
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gen_onIdle <- function(user_func, fps_target = 30, show_fps = FALSE, this_dev,
                       double_buffer = TRUE, verbose = FALSE) {

  double_buffer <- isTRUE(double_buffer)

  x          <- 0.5
  y          <- 0.5
  width      <- graphics::grconvertX(1, 'ndc', 'device')
  height     <- graphics::grconvertY(0, 'ndc', 'device')
  frame_num  <- 0L

  if (isTRUE(verbose)) {
    message("Width: ", width, "  Height: ", height)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Make extra, extra sure that 'fps_target' is a numeric, as this is
  # used in 'fps_governor' and treated as if it *MUST* be numeric or
  # NA_REAL.  Any other value handed into the C code could be segfault-y
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (is.null(fps_target)) fps_target <- NA_real_
  fps_target <- as.numeric(fps_target)

  fs <- init_fps_governor()

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Define the actual callback function which is a wrapper around the
  # the users function
  # This final onIdle callback function:
  #   - stores any current (x,y) coords (regardless of whether the user
  #     handles them in some other way on a per-event basis within the
  #     user_func()
  #   - advances the frame_num by 1
  #   - checks in with the fps_governor()
  #   - calls the user_func()
  #   - tidies up
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  function() {

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Before calling the user_func() at each idle event
    #  - get the event environment for our graphics device
    #  - get the event that might have been placed in there
    #  - increment the frame number
    #
    # If an event actually happened (i.e. event != NULL)
    #  - copy the x/y coords into the user_func() environment
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    event_env <- grDevices::getGraphicsEventEnv(which = this_dev)
    event     <- event_env$event

    frame_num <<- frame_num + 1L

    if (!is.null(event) && event$type %in% c('mouse_move', 'mouse_down', 'mouse_up')) {
      x <<- event$x
      y <<- event$y
    }

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Try and maintain the 'fps_target' set by the user.
    # The return value is the 'actual_fps' that's currently happening
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    fps_actual <- fps_governor(fps_target, fs)

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # To prevent tearing, call a 'dev.hold()' first, then call the
    # users function, then fluh the device
    # Probably devices where this will help:  x11(type='dbcairo'), quartz()
    #  and windows()
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (double_buffer) grDevices::dev.hold()
    user_func(
      event      = event_env$event,
      mouse_x    = x,
      mouse_y    = y,
      frame_num  = frame_num,
      fps_actual = fps_actual,
      fps_target = fps_target,
      dev_width  = width,
      dev_height = height
    )

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Add in FPS info in bottom corner if requested
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (show_fps) {
      grid::grid.rect(
        x      = 0,
        y      = 0,
        width  = grid::unit(250, 'points'),
        height = grid::unit( 55, 'points'),
        gp = grid::gpar(
          fill  = 'white',
          alpha = 0.5
        )
      )

      grid::grid.text(
        label = paste("FPS:", round(fps_actual)),
        x     = 0.01,
        y     = 0.01,
        just  = c('left', 'bottom'),
        gp = grid::gpar(
          fontfamily = 'mono',
          cex        = 2,
          col        = 'black'
        )
      )
    }


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Flush the drawing commands to the device
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (double_buffer) grDevices::dev.flush()

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Clear the event after each call to the user_func()
    # If the user hasn't handled it by now, they've missed it!
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    event_env$event <- NULL

    NULL
  }

}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Run the user supplied function within an event loop in a new graphics window
#'
#' Create a new \code{X11()} graphics device and setup event callbacks such
#' that the user-supplied callback function is run with appropriate
#' parameters at the specified rate.
#'
#' @param user_func user-supplied callback function. This function will be
#'        run by the system at the rate specified by \code{fps_target}.
#'
#'        At a minimum, this function should accept the \code{...} argument,
#'        but the current full list of allowed arguments is:
#'        \describe{
#'          \item{\code{event}}{ - Event information from the graphics device.
#'                This is NULL when no event occurred, otherwise it is a list
#'                with a \code{type} element where:
#'                \itemize{
#'                \item{\code{event$type = 'mouse_down'} indicates a mouse button
#'                      was clicked. \code{event$button} gives the integer
#'                      index of the button.}
#'                \item{\code{event$type = 'mouse_up'} indicates a mouse button
#'                      was released. \code{event$button} gives the integer
#'                      index of the button.}
#'                \item{\code{event$type = 'mouse_move'} indicates the mouse
#'                      was moved. \code{event$button} gives the integer
#'                      index of the button being pressed}
#'                \item{\code{event$type = 'key_press'} indicates a key was pressed
#'                      on the keyboard. \code{event$str} holds the identifier as
#'                      to what was pressed as
#'                      a string value. Note: this string can be multiple characters because
#'                      of how the graphics device treats modifier keys like CTRL,
#'                      and arrow keys (UP, LEFT, RIGHT, DOWN).  See docs for
#'                      \code{grDevices::setGraphicsEventHandlers} to learn more.}
#'                }
#'          }
#'          \item{\code{mouse_x, mouse_y}}{ - current location of mouse within window in normalised
#'          coordinates in the range [0, 1]. If mouse is
#'        not within window, this will be set to the last available coordinates}
#'          \item{\code{frame_num}}{ - Current frame number (integer)}
#'          \item{\code{fps_actual, fps_target}}{ - the curent framerate and the framerate specified
#'        by the user}
#'          \item{\code{dev_width, dev_height}}{ - the width and height of the output device
#'          in pixels. Note: this does not cope with window resizing}
#'          \item{\code{...}}{ - Catch any other arguments.  Note that this is
#'                a required argument in all \code{user_func} callback functions}
#'        }
#' @param width,height size of graphics device to open in inches. Default: 7x7 inches
#' @param fps_target target frames-per-second.  If rendering speed surpasses
#'        this then slight pauses will be added to each loop to bring this
#'        back to the target rate. Set to NA to run as fast as possible.  Note
#'        that even though the user supplied function might be called at a very
#'        high rate, the actual screen update rate may be much much lower.
#' @param show_fps show the fps as text in the bottom left of the window.
#'        Default: FALSE
#' @param double_buffer use a double buffered device? Default: TRUE.  A
#'        double buffered device is essential if you are updating the display
#'        every frame e.g. a game of SuperMario.   For more static games
#'        e.g Chess, there's no need to double buffer as you are only updating
#'        the game when user events occur (like moving a chess piece).  Double
#'        buffered devices avoid "screen tearing" when rendering, but because
#'        of the way R handles the dev.hold/dev.flush operations, the mouse
#'        will flicker between a normal pointer and a busy pointer.
#' @param verbose Show more debugging information. Default: FALSE
#'
#' @return None. This function returns nothing, and  only terminates when the user
#'         presses \code{ESC} within the window, or some other terminating
#'         condition occurs e.g. an error
#'
#' @examples
#' if (interactive()) {
#'   my_fun <- function(...) { cat(".") }
#'   run_loop(my_fun)
#' }
#'
#' @importFrom methods formalArgs
#' @import grDevices
#' @import graphics
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run_loop <- function(user_func, width = 7, height = 7, fps_target = 30, show_fps = FALSE,
                     double_buffer = TRUE, verbose = FALSE) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Sanity Check: Operating System
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (.Platform$OS.type == 'windows') {
    stop("The 'eventloop' package is not compatible with windows because the ",
         "graphics devices do not support the required interaction events")
  }


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Sanity Check: User func
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (!is.function(user_func)) {
    stop("'user_func' must be a function")
  }

  if (!('...' %in% formalArgs(user_func))) {
    warning("'user_func' must have a '...' argument to ensure future compatibility")
  }



  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Double buffering isn't always required
  # E.g. a purely reactive app which only changes when the user clicks can
  # be "single buffered".
  # Double buffering appears "ugly" in some circumstances as the mouse will
  # flicker between 'busy' and 'non-busy' icons
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (double_buffer) {
    type <- 'dbcairo'
  } else {
    type <- 'nbcairo'
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Create a device and capture its device number.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  devs1 <- dev.list()
  grDevices::x11(type = type, width = width, height = height)
  devs2 <- dev.list()
  this_dev <- setdiff(devs2, devs1)
  on.exit(grDevices::dev.off(which = this_dev))

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Turn off the displaylist as this device has no need to capture what
  # has been drawn to it.
  # Note: the onIdle() function will paint/repaint this window *EVERY SINGLE
  # CALL* - this is going to be a lot of events that are cpatured in
  # a displaylist with no real use. So set displaylist='inhibit' and
  # never both capturing anything.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  grDevices::dev.control(displaylist = 'inhibit')

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Wrap the users callback function in the infrastructure which passes in
  # all the parameters at each call.
  # This wrapped version of the users callback is then the 'onIdle'
  # callback in the event handler
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  onIdle <- gen_onIdle(
    user_func,
    fps_target    = fps_target,
    show_fps      = show_fps,
    this_dev      = this_dev,
    double_buffer = double_buffer,
    verbose       = verbose
  )

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Set up the events on this device
  #  - the mouse_up, mouse_down, mouse_move and keyboard callbacks are
  #    not currently customisable
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  grDevices::setGraphicsEventHandlers(
    which         = this_dev,
    prompt        = '',
    onMouseDown   = onMouseDown,
    onMouseUp     = onMouseUp,
    onMouseMove   = onMouseMove,
    onIdle        = onIdle,
    onKeybd       = onKeybd
  )

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Initialise the 'event' data to NULL.
  # this 'event' will be set to not-NULL in any of the mouse/keyboard
  # callbacks when an event occurs
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  event_env <- grDevices::getGraphicsEventEnv(which = this_dev)
  event_env$event <- NULL

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  cat('Starting Event Loop. Press ESC in window to quit.')
  grDevices::getGraphicsEvent()

  invisible(NULL)
}








