
// #define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

extern SEXP fps_governor_();

static const R_CallMethodDef CEntries[] = {

  {"fps_governor_", (DL_FUNC) &fps_governor_, 1},
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



