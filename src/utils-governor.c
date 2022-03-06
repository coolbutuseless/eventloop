


#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// This is a "good enough" FPS governor in C
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SEXP fps_governor_(SEXP fps_target_) {
  static int init = 0;
  double fps_target = asReal(fps_target_);
  static double fps_actual = 30;
  static struct timeval last_time;
  static struct timeval checkpoint_time;
  struct timeval this_time;


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // On first call just init everything, but don't wait around.
  // This is "good enough" for now. Mike 2022-03-01
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (init == 0) {
    init++;
    gettimeofday(&last_time      , NULL);
    gettimeofday(&checkpoint_time, NULL);
    if (fps_target == NA_REAL) {
      fps_actual = 30;
    } else {
      fps_actual = asReal(fps_target_);
    }
    return ScalarReal(fps_actual);
  }

  init++;
  gettimeofday(&this_time, NULL);

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Simple fps averaged over the last 10 frames
  // This is "good enough" for now. Mike 2022-03-01
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (init % 10 == 0) {
    double actual = (this_time.tv_sec + this_time.tv_usec/1000000.0) -
      (checkpoint_time.tv_sec + checkpoint_time.tv_usec/1000000.0);
    fps_actual = 10 / actual;
    memcpy(&checkpoint_time, &this_time, sizeof(struct timeval));
    // Rprintf(">> %.2f", fps);
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Find the current time and work our how long to wait
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (fps_target != NA_REAL || fps_target < 1) {
    double actual = (this_time.tv_sec + this_time.tv_usec/1000000.0) -
      (last_time.tv_sec + last_time.tv_usec/1000000.0);
    double expected = 1.0/asReal(fps_target_);
    double wait = (expected - actual) * 1e6;

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Factor in a tiny bit of overhead and 'wait' for this amount of time.
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (wait > 3000) {
      usleep(wait - 3000);
    }
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Reset the clock so we can get an accurate frame time next run
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gettimeofday(&last_time, NULL);

  return ScalarReal(fps_actual);
}
