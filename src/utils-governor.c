


#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// An 'fps_struct' holding global information  about the timing
//
// We need this idea of a 'struct' that the user initialises so that we
// can properly initialise the FPS counter over multiple runs.
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
SEXP fps_governor_(SEXP fps_target_, SEXP fs_) {

  const double alpha = 0.7;
  struct timeval this_time;
  double fps_target = asReal(fps_target_);

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

    if (ISNA(fps_target)) {
      fs->avg_frame_interval = 1.0/30.0;
      return ScalarReal(30.0);
    } else {
      fs->avg_frame_interval = 1.0/fps_target;
      return ScalarReal(fps_target);
    }
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
  double wait = 0.0;

  if (!ISNA(fps_target)) {
    double expected_frame_interval = 1.0/asReal(fps_target_);
    wait = expected_frame_interval - fs->avg_frame_interval;


    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Factor in a tiny bit of overhead and 'wait' for this amount of time.
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (wait > 0) {
      double uwait = wait * 1e6 - 2000;
      if (uwait > 0) usleep(uwait);
    } else {
      wait = 0.0;
    }
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Reset the 'last_time'
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  gettimeofday(fs->last_time, NULL);

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Return Actual FPS to user
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  return ScalarReal(1.0/(fs->avg_frame_interval + wait));
}






