

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mouse Click
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onMouseDown <- function(button, x, y) {

  event_env <- grDevices::getGraphicsEventEnv()

  event_env$event <- list(
    type   = 'click',
    button = button,
    x      = x,
    y      = y,
    X      = graphics::grconvertX(x, 'ndc', 'device'),
    Y      = graphics::grconvertY(y, 'ndc', 'device')
  )

  NULL
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mouse release
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onMouseUp <- function(button, x, y) {

  event_env <- getGraphicsEventEnv()

  event_env$event <- list(
    type   = 'release',
    button = button,
    x      = x,
    y      = y,
    X      = graphics::grconvertX(x, 'ndc', 'device'),
    Y      = graphics::grconvertY(y, 'ndc', 'device')
  )

  NULL
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mouse Move
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onMouseMove <- function(button, x, y) {

  event_env <- grDevices::getGraphicsEventEnv()

  if (is.null(event_env$event)) {
    event_env$event <- list(
      type   = 'move',
      button = button,
      x      = x,
      y      = y,
      X      = graphics::grconvertX(x, 'ndc', 'device'),
      Y      = graphics::grconvertY(y, 'ndc', 'device')
    )
  }

  NULL
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Keyboard handler
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onKeybd <- function(char) {

  event_env <- grDevices::getGraphicsEventEnv()

  event_env$event <- list(
    type = 'key',
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
gen_onIdle <- function(user_func, target_fps = 20) {

  func_env <- environment(user_func)
  func_env$event  <- NULL
  func_env$frame  <- 0L
  func_env$x      <- 0
  func_env$y      <- 0
  func_env$X      <- 0
  func_env$Y      <- 0
  func_env$height <- 0
  func_env$width  <- 0

  func_env$fps    <- fps_governor(target_fps)

  first_frame <- TRUE

  function() {
    event_env      <- grDevices::getGraphicsEventEnv()
    event          <- event_env$event
    func_env$event <- event
    func_env$frame <- func_env$frame + 1L

    if (!is.null(event) && event$type %in% c('move', 'click', 'release')) {
      func_env$x <- event$x
      func_env$y <- event$y
      func_env$X <- event$X
      func_env$Y <- event$Y
    }

    if (first_frame) {
      func_env$width  <- graphics::grconvertX(1, 'ndc', 'device')
      func_env$height <- graphics::grconvertY(0, 'ndc', 'device')
      func_env$starttime <- Sys.time()
      first_frame <<- FALSE
    }

    grDevices::dev.hold()
    user_func()
    grDevices::dev.flush()



    # Clear the events
    event_env$event <- NULL
    func_env$event  <- NULL

    func_env$fps    <- fps_governor(target_fps)

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

  devs1 <- dev.list()
  grDevices::x11(type = 'dbcairo', width = width, height = height)
  devs2 <- dev.list()
  this_dev <- setdiff(devs2, devs1)
  on.exit(grDevices::dev.off(which = this_dev))

  grDevices::dev.control(displaylist = 'inhibit')

  onIdle <- gen_onIdle(user_func, target_fps = target_fps)

  grDevices::setGraphicsEventHandlers(
    prompt        = '',
    onMouseDown   = onMouseDown,
    onMouseUp     = onMouseUp,
    onMouseMove   = onMouseMove,
    onIdle        = onIdle,
    onKeybd       = onKeybd
  )

  event_env <- grDevices::getGraphicsEventEnv()
  event_env$event <- NULL

  cat('Starting Game Loop ... ')
  grDevices::getGraphicsEvent()

  invisible(NULL)
}








