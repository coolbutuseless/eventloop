

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Governor for frame rate
#'
#' Given a target FPS, this function will insert pauses to ensure it can
#' be called no more than this number of times per second (give or take a little
#' bit)
#'
#' @param fps target frames per second i.e. the desired frrame rate
#' @param fs an FPS Structure storing global information for the FPS governor.
#'        Create this object initially with \code{fs = init_fps_governor()}
#' @return The current actual framerate
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fps_governor <- function(fps) {
  .Call(fps_governor_, fps)
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' @rdname fps_governor
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fps_governor_new <- function(fps, fs) {
  .Call(fps_governor_new_, fps, fs)
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' @rdname fps_governor
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init_fps_governor <- function() {
  .Call(init_fps_governor_)
}



if (FALSE) {

  system.time({
    fs <- init_fps_governor()
    for (i in seq(300)) {
      fps_governor_new(60, fs)
    }
  })

}
