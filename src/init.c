
// #define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

extern SEXP fps_governor_();
extern SEXP fps_governor_new_();
extern SEXP init_fps_governor_();

static const R_CallMethodDef CEntries[] = {

  {"fps_governor_", (DL_FUNC) &fps_governor_, 1},
  {"init_fps_governor_", (DL_FUNC) &init_fps_governor_, 0},
  {"fps_governor_new_", (DL_FUNC) &fps_governor_new_, 2},
  {NULL , NULL, 0}
};


void R_init_eventloop(DllInfo *info) {
  R_registerRoutines(
    info,      // DllInfo
    NULL,      // .C
    CEntries,  // .Call
    NULL,      // Fortran
    NULL       // External
  );
  R_useDynamicSymbols(info, FALSE);
}



