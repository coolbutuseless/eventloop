

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Governor for frame rate
#'
#' Given a target FPS, this function will insert pauses to ensure it can
#'
#' @param fps target frames per second i.e. the desired frrame rate
#' @param fs an FPS Structure storing global information for the FPS governor.
#'        Create this object initially with \code{fs = init_fps_governor()}
#' @return The current actual framerate
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fps_governor <- function(fps, fs) {
  .Call(fps_governor_, fps, fs)
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' @rdname fps_governor
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init_fps_governor <- function() {
  .Call(init_fps_governor_)
}



if (FALSE) {

  system.time({
    fs <- init_fps_governor()
    for (i in seq(300)) {
      fps_governor(60, fs)
    }
  })

}
