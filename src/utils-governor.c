


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


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// An 'fps_struct' holding global information  about the timing
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typedef struct fps_struct {
  struct timeval *last_time;
  double avg_frame_interval;
  unsigned int init;
} fps_struct;



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// How to finalize an external pointer holding an 'fps_struct'
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void fps_struct_finalizer(SEXP fs_) {
  // Rprintf("fps_struct finalizer called\n");
  fps_struct *fs = R_ExternalPtrAddr(fs_);
  free(fs->last_time);
  free(fs);
  R_ClearExternalPtr(fs_);
}



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Let an R user create an fps struct
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SEXP init_fps_governor_() {
  struct fps_struct *fs = calloc(1, sizeof(fps_struct));
  if (fs == NULL) {
    error("Could allocate memory for fps_struct");
  }
  fs->last_time = malloc(sizeof(struct timeval));

  SEXP fs_ = PROTECT(R_MakeExternalPtr(fs, R_NilValue, R_NilValue));
  R_RegisterCFinalizer(fs_, fps_struct_finalizer);
  SET_CLASS(fs_, mkString("fps_struct"));

  UNPROTECT(1);
  return fs_;
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// This is a "good enough" FPS governor in C
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SEXP fps_governor_new_(SEXP fps_target_, SEXP fs_) {

  const double alpha = 0.7;
  struct timeval this_time;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Unpack this external pointer
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (!inherits(fs_, "fps_struct")) {
    error("Expecting 'fs' to be an 'fps_struct' ExternalPtr as created by 'init_fps_governor()'");
  }

  fps_struct *fs = TYPEOF(fs_) != EXTPTRSXP ? NULL : (fps_struct *)R_ExternalPtrAddr(fs_);
  if (fs == NULL) {
    error("'fs' structure storing FPS info is invalid");
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // On first call just init everything and return immediately.
  // This is "good enough" for now. Mike 2022-03-01
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (fs->init == 0) {
    fs->init++;
    gettimeofday(fs->last_time, NULL);
    fs->avg_frame_interval = 1.0/30.0;
    return fps_target_;
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Get the current time and calculate difference from last time
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gettimeofday(&this_time, NULL);

  double this_frame_interval =
    (this_time.tv_sec  - fs->last_time->tv_sec ) +
    (this_time.tv_usec - fs->last_time->tv_usec) / 1000000.0;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Calculate the exponential weighted moving average of the frame
  // interval time
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  fs->avg_frame_interval = alpha * fs->avg_frame_interval + (1.0 - alpha) * this_frame_interval;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // How long should we wait if we want to meet the expected frame
  // interval time for this target FPS?
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  double expected_frame_interval = 1.0/asReal(fps_target_);
  double wait = expected_frame_interval - fs->avg_frame_interval;


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Factor in a tiny bit of overhead and 'wait' for this amount of time.
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (wait > 0) {
    double uwait = wait * 1e6;
    if (uwait > 2000) usleep(uwait - 2000);
  } else {
    wait = 0.0;
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Reset the 'last_time'
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gettimeofday(fs->last_time, NULL);

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Return FPS to user
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  return ScalarReal(1.0/(fs->avg_frame_interval + wait));
}






