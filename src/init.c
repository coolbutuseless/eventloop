
// #define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

extern SEXP sleep_();

static const R_CallMethodDef CEntries[] = {

  {"sleep_", (DL_FUNC) &sleep_, 1},
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



