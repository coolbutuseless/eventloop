


#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>
//#include <cairo/cairo.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// #include "aaa.h"
// #include "R-finalizers.h"


SEXP hello_() {
  Rprintf("Hello from c\n");

  return R_NilValue;
}
