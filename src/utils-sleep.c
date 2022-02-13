


#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>



SEXP sleep_(SEXP seconds_) {
  usleep(asReal(seconds_) * 1e6);
  return R_NilValue;
}
