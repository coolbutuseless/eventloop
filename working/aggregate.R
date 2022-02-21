

N <- 10
m <- matrix(seq(N*2), ncol = 2)

m <- cbind(m, rep(1:2, each = 5))
m



aggregate(m, by = list(m[, 3]), FUN = function(x) {x[1] + x[2]})
