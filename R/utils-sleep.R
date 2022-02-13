

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Sleep in seconds
#'
#' Avoid \code{Sys.sleep()} in event loops as per docuemntation for
#' \code{grDevices:::getGraphicsEvent}.  \code{Sys.sleep()} actually removes
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
