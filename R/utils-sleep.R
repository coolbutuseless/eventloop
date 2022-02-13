

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Sleep in seconds
#'
#' Avoid 'Sys.sleep()' as it does not interact with getting X11 event data
#'
#' @param seconds time in seconds. can be fractional. will be converted to
#'        microseconds and called with 'usleep()' in C
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sleep <- function(seconds) {
  invisible(.Call(sleep_, seconds))
}
