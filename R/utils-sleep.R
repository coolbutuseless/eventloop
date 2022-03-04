

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Governor for frame rate
#'
#' Given a target FPS, this function will insert pauses to ensure it can
#' be called no more than this number of times per second (give or take a little
#' bit)
#'
#' @param fps target frames per second
#' @return actual fps calculated over last 10 frames
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fps_governor <- function(fps) {
  .Call(fps_governor_, fps)
}
