# eventloop 0.1.1  2022-05-12

* Add a new argument to `user_func` i.e. `event_env` environment object.  Use
  this to pass particular values back to the rendering framework.
    * Programattic closing of the interactive window from within `user_func`
      by setting `event_env$close` to a non-NULL value
    * Allow the user to adjust FPS from within the `user_func` by setting 
      `event_env$fps_target`

# eventloop 0.1.0  2022-05-06

* Initial release
