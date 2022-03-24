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
    layout = grid::grid.layout(nrow = n, ncol = 1, heights = vs$rel_heights)
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
    layout = grid::grid.layout(nrow = 1, ncol = n, widths = hs$rel_widths)
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



ui_spec <- hstack(
  elem("Ask" , button(textGrob('Ask' )) , width = 2),
  elem("Do"  , button(textGrob('Do'  ))),
  vstack(
    elem("Ask" , button(textGrob('Ask' )) , height = 0.5),
    elem("Do"  , button(textGrob('Do'  ))),
    hstack(
      elem("a", button(textGrob("a"))),
      elem("b", button(textGrob("b"))),
      elem("c", button(textGrob("c"))),
      elem("d", button(textGrob("d")))
    )
  )
)


# ui_spec
g <- NULL
g <- ui_spec_to_grobTree(ui_spec)


x11(type = 'cairo', antialias = 'none')
dev.control(displaylist = 'inhibit')
grid.newpage()
grid.draw(g)








