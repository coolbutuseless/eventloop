

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mouse Click
# - The event loop will terminate as soon as this returns any non-NULL object
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
# Mouse release
# - The event loop will terminate as soon as this returns any non-NULL object
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onMouseUp <- function(button, x, y) {

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
# Mouse Move
# - The event loop will terminate as soon as this returns any non-NULL object
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
# Keyboard handler
# - The event loop will terminate as soon as this returns any non-NULL object
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onKeybd <- function(char) {

  event_env <- grDevices::getGraphicsEventEnv()

  event_env$event <- list(
    type = 'key_press',
    char = char,
    int  = utf8ToInt(char)
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
# Generate an 'onIdle' callback function that wraps the users target function
#
# This onIdle function prepares variables in the function environment so
# the user doesn't have to do as much.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gen_onIdle <- function(user_func, target_fps = 30, this_dev) {

  x         <- 0.5
  y         <- 0.5
  width     <- graphics::grconvertX(1, 'ndc', 'device')
  height    <- graphics::grconvertY(0, 'ndc', 'device')
  frame_num <- 0L

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Generate the actual callback function which wraps the user-given function
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
    # To prevent tearing, call a 'dev.hold()' first, then call the
    # users function, then fluh the device
    # Probably devices where this will help:  x11(type='dbcairo'), quartz()
    #  and windows()
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    fps <- fps_governor(target_fps)
    grDevices::dev.hold()
    user_func(
      event      = event_env$event,
      mouse_x    = x,
      mouse_y    = y,
      frame_num  = frame_num,
      fps_actual = fps,
      fps_target = target_fps,
      dev_width  = width,
      dev_height = height
    )
    grDevices::dev.flush()

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Clear the events
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    event_env$event <- NULL

    NULL
  }

}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Run the user supplied function as the idle function within the event loop
#'
#' @param user_func user function
#' @param width,height size of graphics device to open. Default: 7x7 inches
#' @param target_fps target frames-per-second.  If rendering speed surpasses
#'        this then slight pauses will be added to each loop to bring this
#'        back to the target rate
#'
#' @return NULL.  The user function is run over-and-over within the event
#'         loop.
#'
#' @import grDevices
#' @import graphics
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run_loop <- function(user_func, width = 7, height = 7, target_fps = 30) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Create a device and capture its device number.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  devs1 <- dev.list()
  grDevices::x11(type = 'dbcairo', width = width, height = height)
  devs2 <- dev.list()
  this_dev <- setdiff(devs2, devs1)
  on.exit(grDevices::dev.off(which = this_dev))

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Turn off the displaylist
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  grDevices::dev.control(displaylist = 'inhibit')

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Wrap the users function in the infrastructure which passes in
  # all the parameters at each call.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  onIdle <- gen_onIdle(user_func, target_fps = target_fps, this_dev = this_dev)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Set up the events on this device
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
  # Initialise the events to NULL
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  event_env <- grDevices::getGraphicsEventEnv(which = this_dev)
  event_env$event <- NULL

  cat('Starting Game Loop ... ')
  grDevices::getGraphicsEvent()

  invisible(NULL)
}








