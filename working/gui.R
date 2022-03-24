library(grid)


# User defines UI in some declarative form
# User specifies size and location to render UI
# I translate specification
#   - into a grob tree to render
#   - into some data.strcutre which is easy to lookup which element is
#     hit by the current mouse position.
# Some standard function to take (1) GUI data.structure, and (2) mouse coords
# and quickly return the ID that is hit by this.  (or NULL if no hits)



# x11(type = 'cairo', antialias = 'none')
# dev.control(displaylist = 'inhibit')


pink <- rectGrob(gp = gpar(fill = 'hotpink'))
blue <- rectGrob(gp = gpar(fill = 'lightblue'))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Wrap a grob to make it look slightly more like a button with a smidgen
# of bas relief shading
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
button <- function(grob) {
  u <- unit(1, 'mm')
  du <- unit(1, 'npc') - u
  u2 <- 2 * u
  hf <- unit(0.5, 'npc')
  one <- unit(1, 'npc')
  grid::grobTree(
    grob,
    grid.rect(
      x = unit.c(u, du, hf, hf),
      y = unit.c(hf, hf, u, du),
      width = unit.c(u2, u2, one, one),
      height = unit.c(one, one, u2, u2),
      gp = gpar(fill = c('grey80', 'grey30', 'grey30', 'grey80'), col = NA)
    )
  )
  # grob
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create a UI element
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
elem <- function(id, grob, height = 1, width = 1) {

  stopifnot(grid::is.grob(grob))
  stopifnot(is.character(id))
  stopifnot(is.numeric(height))
  stopifnot(is.numeric(width))

  res <- list(
    type   = 'elem',
    id     = id,
    grob   = grob,
    height = height,
    width  = width
  )

  class(res) <- 'elem'
  res
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create a vertical stack of UI elements
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
vstack <- function(..., width = 1, height = 1) {
  elems <- list(...)
  stopifnot(length(elems) > 0)

  are_elems <- purrr::map_lgl(elems, ~inherits(.x, 'elem'))
  stopifnot(all(are_elems))

  heights <- purrr::map_dbl(elems, 'height')

  n <- length(elems)
  res <- list(
    type        = 'vstack',
    heights     = heights,
    rel_heights = heights/sum(heights),
    contents    = elems,
    width       = width,
    height      = height
  )

  class(res) <- 'elem'
  res
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create a horiontal stack of UI elements
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hstack <- function(..., width = 1, height = 1) {
  elems <- list(...)
  stopifnot(length(elems) > 0)

  are_elems <- purrr::map_lgl(elems, ~inherits(.x, 'elem'))
  stopifnot(all(are_elems))

  widths <- purrr::map_dbl(elems, 'width')

  n <- length(elems)
  res <- list(
    type       = 'hstack',
    widths     = widths,
    rel_widths = widths/sum(widths),
    contents   = elems,
    width      = width,
    height     = height
  )

  class(res) <- 'elem'
  res
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert 'vstack' UI element to a grob
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
vstack_to_grob <- function(vs) {

  if (!identical(vs$type, 'vstack')) {
    stop("Expected type = vstack, but got: ", vs$type)
  }

  n <- length(vs$contents)
  fg <- frameGrob(
    layout = grid::grid.layout(nrow = n, ncol = 1, heights = unit(vs$rel_heights, 'npc'))
  )
  for (i in seq_len(n)) {
    if (vs$contents[[i]]$type == 'vstack') {
      grob <- vstack_to_grob(vs$contents[[i]])
    } else if (vs$contents[[i]]$type == 'hstack') {
      grob <- hstack_to_grob(vs$contents[[i]])
    } else {
      grob <- vs$contents[[i]]$grob
    }
    fg <- placeGrob(fg, grob, row = i, col = 1)
  }
  fg
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert 'hstack' UI element to a grob
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hstack_to_grob <- function(hs) {

  if (!identical(hs$type, 'hstack')) {
    stop("Expected type = hstack, but got: ", hs$type)
  }

  n <- length(hs$contents)
  fg <- frameGrob(
    layout = grid::grid.layout(nrow = 1, ncol = n, widths = unit(hs$rel_widths, 'npc'))
  )
  for (i in seq_len(n)) {
    if (hs$contents[[i]]$type == 'vstack') {
      grob <- vstack_to_grob(hs$contents[[i]])
    } else if (hs$contents[[i]]$type == 'hstack') {
      grob <- hstack_to_grob(hs$contents[[i]])
    } else {
      grob <- hs$contents[[i]]$grob
    }
    fg <- placeGrob(fg, grob, row = 1, col = i)
  }
  fg
}


ui_spec_to_grobTree <- function(ui_spec) {
  if (identical(ui_spec$type, 'vstack')) {
    vstack_to_grob(ui_spec)
  } else if (identical(ui_spec$type, 'hstack')) {
    hstack_to_grob(ui_spec)
  } else {
    stop("'ui_spec' is expected to be a hstack or vstack element")
  }
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Split extents for child elements
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
vsplit_extents <- function(extents, heights) {
  fac <- head(cumsum(c(0, heights)), -1)

  extents$x <- rep(extents$x, length(heights))
  extents$w <- rep(extents$w, length(heights))

  extents$y <- extents$y + fac * extents$h
  extents$h <- heights * extents$h

  extents <- purrr::transpose(extents)
  extents
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Split extents for child elements
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hsplit_extents <- function(extents, widths) {
  fac <- head(cumsum(c(0, widths)), -1)

  extents$y <- rep(extents$y, length(widths))
  extents$h <- rep(extents$h, length(widths))

  extents$x <- extents$x + fac * extents$w
  extents$w <- widths * extents$w

  extents <- purrr::transpose(extents)
  extents
}





hs <- hstack(
  elem("Ask" , button(textGrob('Ask' ))),
  elem("Do"  , button(textGrob('Do'  )), width = 2),
  elem("Quit"  , button(textGrob('Quit'  )))
)



vs <- vstack(
  elem("Ask" , button(textGrob('Ask' ))),
  elem("Do"  , button(textGrob('Do'  )), width = 2),
  elem("Quit"  , button(textGrob('Quit'  )))
)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert 'hstack' an extents_df
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hstack_to_extents_df <- function(hs, parent_extents) {

  if (!identical(hs$type, 'hstack')) {
    stop("Expected type = hstack, but got: ", hs$type)
  }

  n <- length(hs$contents)
  widths <- hs$rel_widths

  extents <- hsplit_extents(parent_extents, widths)

  extents_df <- list()

  for (i in seq_len(n)) {
    if (hs$contents[[i]]$type == 'vstack') {
      extents_df[[i]] <- vstack_to_extents_df(hs$contents[[i]], extents[[i]])
    } else if (hs$contents[[i]]$type == 'hstack') {
      extents_df[[i]] <- hstack_to_extents_df(hs$contents[[i]], extents[[i]])
    } else {
      extents_df[[i]] <- as.data.frame(extents[[i]])
      extents_df[[i]]$id <- hs$contents[[i]]$id
    }
  }


  do.call('rbind', extents_df)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert 'hstack' an extents_df
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
vstack_to_extents_df <- function(vs, parent_extents) {

  if (!identical(vs$type, 'vstack')) {
    stop("Expected type = vstack, but got: ", vs$type)
  }

  n <- length(vs$contents)
  heights <- vs$rel_heights

  extents <- vsplit_extents(parent_extents, heights)

  extents_df <- list()

  for (i in seq_len(n)) {
    if (vs$contents[[i]]$type == 'vstack') {
      extents_df[[i]] <- vstack_to_extents_df(vs$contents[[i]], extents[[i]])
    } else if (vs$contents[[i]]$type == 'hstack') {
      extents_df[[i]] <- hstack_to_extents_df(vs$contents[[i]], extents[[i]])
    } else {
      extents_df[[i]] <- as.data.frame(extents[[i]])
      extents_df[[i]]$id <- vs$contents[[i]]$id
    }
  }


  do.call('rbind', extents_df)
}





ui_spec_to_extents_df <- function(ui_spec) {

  parent_extents <- list(x=0, y=0, w=1, h=1)

  if (identical(ui_spec$type, 'hstack')) {
    extents_df <- hstack_to_extents_df(ui_spec, parent_extents)
  } else if (identical(ui_spec$type,'vstack')) {
    extents_df <- vstack_to_extents_df(ui_spec, parent_extents)
  } else {
    stop("Bad ui_spec type. must be 'hstack' or 'vstack'")
  }

  if (anyDuplicated(extents_df$id)) {
    warning("Duplicate 'id' in ui_spec.")
  }

  extents_df$y2 <- 1 - extents_df$y
  extents_df$y1 <- extents_df$y2 - extents_df$h

  extents_df$x1 <- extents_df$x
  extents_df$x2 <- extents_df$x + extents_df$w

  extents_df <- extents_df[, c('id', 'x1', 'y1', 'x2', 'y2')]

  extents_df
}





ui_spec <- hstack(
  elem("Do" , button(textGrob('Do' )) , width = 2),
  elem("Make"  , button(textGrob('Make'  ))),
  vstack(
    elem("Say" , button(textGrob('Say' )) , height = 0.5),
    elem("Think"  , button(textGrob('Think'  ))),
    hstack(
      elem("a", button(textGrob("a"))),
      elem("b", button(textGrob("b"))),
      elem("c", button(textGrob("c"))),
      elem("d", button(textGrob("d")))
    )
  )
)





extents_df <- ui_spec_to_extents_df(ui_spec)
print(extents_df)


# ui_spec
g <- NULL
g <- ui_spec_to_grobTree(ui_spec)



x11(type = 'cairo', width = 8, height = 6, antialias = 'none')
# dev.control(displaylist = 'inhibit')
grid.newpage()
grid.draw(g)


locate <- function() {
  v <- grid.locator(unit = 'npc')
  list(
    x = as.numeric(v$x),
    y = as.numeric(v$y)
  )
}


library(dplyr)

for (i in 1:20) {
  # print("Locate point...")
  coords <- locate()
  # print(coords)


  res <- extents_df %>%
    filter(coords$x >= x1, coords$x < x2,
           coords$y >= y1, coords$y < y2)

  print(res$id)
}

# extents <- list(x = 0, y = 0, w = 1, h = 1)
# heights <- c(0.3, 0.4, 0.3)







# library(ggplot2)
# ggplot(extents_df) +
#   geom_rect(aes(xmin=x, ymin=y, xmax=x+w, ymax=y+h), fill = NA, colour = 'red')
#
#

















