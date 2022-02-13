
// #define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

extern SEXP hello_();

static const R_CallMethodDef CEntries[] = {

  {"hello_", (DL_FUNC) &hello_, 0},
  {NULL , NULL, 0}
};


void R_init_{package}(DllInfo *info) {
  R_registerRoutines(
    info,      // DllInfo
    NULL,      // .C
    CEntries,  // .Call
    NULL,      // Fortran
    NULL       // External
  );
  R_useDynamicSymbols(info, FALSE);
}



