

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Sleep in seconds
#'
#' This is a custom bit of C code to pause the computer for a bit.
#'
#' For an eventloop, need to avoid \code{Sys.sleep()}, as discussed in the
#'  documentation for
#' \code{grDevices:::getGraphicsEvent}.  This is because \code{Sys.sleep()} actually removes
#' pending graphics events and is going to mess up this whole system.
#'
#' @param seconds time in seconds. can be fractional. will be converted to
#'        microseconds and called with 'usleep()' in C
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sleep <- function(seconds) {
  invisible(.Call(sleep_, seconds))
}


#' @rdname sleep
#' @param fps frames per second
#' @return actual fps calculated over last 10 frames
#' @export
fps_governor <- function(fps) {
  .Call(fps_governor_, fps)
}
