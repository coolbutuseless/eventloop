

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mouse Click
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onMouseDown <- function(button, x, y) {

  event_env <- getGraphicsEventEnv()

  event_env$event <- list(
    type   = 'click',
    button = button,
    x      = x,
    y      = y,
    X      = grconvertX(x, 'ndc', 'device'),
    Y      = grconvertY(y, 'ndc', 'device')
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
    X      = grconvertX(x, 'ndc', 'device'),
    Y      = grconvertY(y, 'ndc', 'device')
  )

  NULL
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Mouse Move
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onMouseMove <- function(button, x, y) {

  event_env <- getGraphicsEventEnv()

  if (is.null(event_env$event)) {
    event_env$event <- list(
      type   = 'move',
      button = button,
      x      = x,
      y      = y,
      X      = grconvertX(x, 'ndc', 'device'),
      Y      = grconvertY(y, 'ndc', 'device')
    )
  }

  NULL
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Keyboard handler
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
onKeybd <- function(char) {

  event_env <- getGraphicsEventEnv()

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

  func_env$fps    <- target_fps
  func_env$time1  <- Sys.time()
  func_env$timeN  <- Sys.time()
  func_env$sleep  <- 1 / target_fps - 0.0065 # 0.006 = approx total overhead

  first_frame <- TRUE

  function() {
    event_env      <- getGraphicsEventEnv()
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
      func_env$width  <- grconvertX(1, 'ndc', 'device')
      func_env$height <- grconvertY(0, 'ndc', 'device')
      func_env$starttime <- Sys.time()
      first_frame <<- FALSE
    }

    dev.hold()
    user_func()
    dev.flush()


    # if (!is.null(target_fps)) {
    #   N <- as.integer(3 * target_fps)
    #   if (func_env$frame %% N == 0) {
    #     actual_time <- as.numeric(difftime(Sys.time(), func_env$timeN, units = 'secs'))
    #     func_env$fps <- N / actual_time
    #
    #     expected_time <- N / target_fps
    #     adjust <- (expected_time - actual_time) / N
    #
    #     func_env$sleep <- func_env$sleep + adjust
    #     cat(func_env$fps, target_fps, adjust, func_env$sleep, "\n")
    #
    #     func_env$timeN <- Sys.time()
    #   }
    #
    #
    #   if (func_env$sleep > 0) {
    #     sleep(func_env$sleep)
    #   }
    # }

    N <- 30
    if (func_env$frame %% 30 == 0) {
      actual_time <- as.numeric(difftime(Sys.time(), func_env$timeN, units = 'secs'))
      func_env$fps <- N / actual_time
      func_env$timeN <- Sys.time()
    }

    # sleep(0.03)



    event_env$event <- NULL
    func_env$event  <- NULL

    # Something here to track/maintain FPS

    NULL
  }

}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run_loop <- function(user_func, width = 7, height = 7, target_fps = 30) {
  x11(type = 'dbcairo', width = width, height = height)
  on.exit(dev.off())
  dev.control(displaylist = 'inhibit')

  onIdle <- gen_onIdle(user_func, target_fps = target_fps)

  setGraphicsEventHandlers(
    prompt        = '',
    onMouseDown   = onMouseDown,
    onMouseUp     = onMouseUp,
    onMouseMove   = onMouseMove,
    onIdle        = onIdle,
    onKeybd       = onKeybd
  )

  event_env <- getGraphicsEventEnv()
  event_env$event <- NULL

  cat('Starting Game Loop ... ')
  getGraphicsEvent()

}








