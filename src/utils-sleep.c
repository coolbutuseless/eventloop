


#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>



SEXP fps_governor_(SEXP fps_) {
  static int init = 0;
  static double fps = 30;
  static struct timeval last_time;
  static struct timeval checkpoint_time;
  struct timeval this_time;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // On first call just init everything, but don't wait around.
  // This is "good enough"
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (init == 0) {
    init++;
    gettimeofday(&last_time      , NULL);
    gettimeofday(&checkpoint_time, NULL);
    fps = asReal(fps_);
    return ScalarReal(fps);
  }

  init++;
  gettimeofday(&this_time, NULL);

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Simple fps averaged over the last 10 frames
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (init % 10 == 0) {
    double actual = (this_time.tv_sec + this_time.tv_usec/1000000.0) -
      (checkpoint_time.tv_sec + checkpoint_time.tv_usec/1000000.0);
    fps = 10 / actual;
    memcpy(&checkpoint_time, &this_time, sizeof(struct timeval));
    // Rprintf(">> %.2f", fps);
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Find the current time and work our how long to wait
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  double actual = (this_time.tv_sec + this_time.tv_usec/1000000.0) -
    (last_time.tv_sec + last_time.tv_usec/1000000.0);
  double expected = 1.0/asReal(fps_);
  double wait = (expected - actual) * 1e6;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Factor in a tiny bit of overhead
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (wait > 3000) {
    usleep(wait - 3000);
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Reset the clock
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gettimeofday(&last_time, NULL);

  return ScalarReal(fps);
}
