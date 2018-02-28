use Blue,
  do:
    (
      progn

      _(
        defmodule(
          BlueTest,
          do:
            (
              progn
              use ExUnit.Case
              doctest Blue
            )
        )
      )
    )
