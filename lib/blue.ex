defmodule Blue do
  @moduledoc """
  BLUE - Block/Bracket Lisp Underneath Elixir.

  A minimalist LISP toy abusing Elixir own syntax.

  As with any toy, dont take it to seriously, have fun with it,
  experiment and learn.

  Take a look at the code, I tried to see how far I could
  get a nano lisp in elixir without any programming :P.

  [Official Soundtrack](https://www.youtube.com/watch?v=icfq_foa5Mo)

  ## Elixir blocks

  In Elixir you can create blocks by surrounding any number
  of expressions between parens and separating them by using
  either a new line or `;`.

      # An inline block
      iex> {:__block__, _, items} = quote do: (1 ; 2 ; 3)
      iex> items
      [1, 2, 3]


      # Or by breaking lines
      iex> {:__block__, _, items} = quote do: (
      ...>    :one
      ...>    2 ; 3
      ...>    "four"
      ...> )
      iex> items
      [:one, 2, 3, "four"]


  ## The `Blue.blue/1` macro

  Now that we know how to create blocks, lets abuse them
  to evaluate lisp-like expressions.

  Notice that BLUE lisp works with Elixir AST directly
  and thus it has no reader. Instead, just create
  Elixir blocks or lists and feed them to the `blue/1` macro.

  The `blue/1` macro takes a single program and works by
  transforming its list of items into valid Elixir AST
  for function application.

      # Call blue with a program
      iex> (blue 1) == (1) |> blue
      true

      # Of course you can call any Elixir function
      iex> (blue (is_atom ; "hello"))
      false

      # Or call operators by breaking lines
      # Remember all this is just valid Elixir syntax
      iex> (blue (+
      ...>    1
      ...>    2))
      3

      # Calling remote functions also works
      iex> (blue (Macro.camelize ; "blue_velvet"))
      "BlueVelvet"


      # But trying to apply to a non call fails.
      # Remember this is just Elixir itself dressed as blue lisp.
      iex> (blue (1 ; 2))
      ** (BadFunctionError) expected a function, got: 1

  ## BLUE is also a Bracket LISP

  Sometimes using BLUE's Bracket syntax can be useful,
  for example when working with Keyword, or just if you
  prefer not to use Blocks everywhere.

      # A list syntax can also be given to blue
      iex> (blue [is_atom, :hello])
      true

      # And you can alternate between them as
      # needed. To turn a list into a LISP program just
      # remember to call `blue` with it.
      iex> (blue (to_string
      ...>   (blue [tuple_size, hello: :world])
      ...> ))
      "2"


  ## Everything happens at compile time

  All the `blue/1` macro does is: given a list of items
  it expects the first to be a partial function application
  and merely appends the rest of items to it as arguments.

      # Keyword.get([hello: "world], :hola, "mundo")
      iex> (blue (
      ...>   Keyword.get([hello: "world"])
      ...>   :hola
      ...>   "mundo"
      ...> ))
      "mundo"


      # Thats why the anon function wont be called here
      iex> (blue (fn -> 9 end)) |> is_function
      true



      # The following would produce a compilation error.
      # Because `99` would be appended as just another
      # argument to the `fn` form, at compile time.
      iex> Code.eval_string "
      ...>   import Blue
      ...>   (blue ( fn x -> x end ; 99 ))
      ...> "
      ** (FunctionClauseError) no function clause matching in anonymous fn/1 in :elixir_fn.expand/3


      # To work around this, you can use `Kernel.apply/2`
      iex> (blue (apply ; fn x -> x end ; [99] ))
      99

      # Same for function references
      iex> (blue (apply ; &Macro.underscore/1 ; [Blue.Velvet] ))
      "blue/velvet"

  ## Special forms

  ### `&rest` arguments

  Functions in Erlang/Elixir have fixed arity, that is, they cannot
  take a variable number of arguments. To work around this, the convention
  is to make functions take a list as last argument.


  Using `&rest` captures the following items in a list as a single argument.

      # Use it on any function taking lists at last argument
      iex> (blue (Enum.max; &rest; 4; 3; 8; 2))
      8

      # And you can also use it with Bracket syntax
      iex> (blue [OptionParser.parse, &rest, "velvet.bv"])
      {[], ["velvet.bv"], []}


  For example `Kernel.apply/2` takes a function and a list of arguments
  to apply to it.

      iex> (blue (apply; fn x -> x end; [99]))
      99

      iex> (blue (apply
      ...>    fn x, y -> x * y end
      ...>    &rest
      ...>    12
      ...>    2))
      24

  Actually many functions in Elixir take a keyword as last argument, most
  commonly for options. In these cases it's better to use Bracket LISP
  as it's much easy to use with keywords.

      # same as: OptionParser.parse(["-v", "-v"], [aliases: [v: :verbose], strict: [verbose: :count]])
      iex> (blue [
      ...>   OptionParser.parse,
      ...>   &rest, "-v", "-v",
      ...>   &rest, aliases: [v: :verbose], strict: [verbose: :count]
      ...> ])
      {[verbose: 2], [], []}

  ### Blocks strike back

  Since normal block syntax is used as function application inside BLUE LISP, the only way to
  acutally create a block of multiple expressions is by using the `progn` form.

      iex> (blue (progn
      ...>    (a = 3 * 4)
      ...>    (min; 20; a)
      ...> ))
      12

  ### under`_`lisp

  `_` is a convenience that comes handy when using common Elixir forms

      iex> (blue _(if, 1 < 2, do: 22))
      22

      # if you use Blocks you need to actually write the keyword brackets
      iex> (blue (if ; 1 < 2 ; [do: 22]))
      22

      # if you use Brackets you need to use &rest to capture the keyword tuples
      iex> (blue [if, 1 < 2, &rest, do: 22])
      22

  ## `use Blue` on `.ex` files.

  Since BLUE programs use only valid Elixir syntax, you can write LISP programs on `ex` files.
  The `mix format` tool however will not play nicely with lispy aesthetics.

  As an example, see `blue_test.exs` file.

      use Blue, do: (progn
        _(defmodule BlueTest, do: (progn
          (use ExUnit.Case)
          (doctest Blue)
        )))



  """

  @doc false
  defmacro __using__(do: code) do
    quote do
      import Blue
      unquote(Macro.prewalk(code, &prewalk/1))
    end
  end

  defmacro blue(code) when is_list(code), do: Macro.prewalk({:_, [], code}, &prewalk/1)
  defmacro blue(code), do: Macro.prewalk(code, &prewalk/1)

  defp prewalk({:__block__, m, [{:progn, _, x} | r]}) when is_atom(x), do: {:__block__, m, r}

  defp prewalk({ul, meta, [head | rest]}) when ul == :__block__ or ul == :_ do
    case Macro.decompose_call(head) do
      {name, first} -> {name, meta, first ++ rest}
      {remote, name, first} -> {{:., meta, [remote, name]}, meta, first ++ rest}
      :error -> {{:., meta, [head]}, meta, rest}
    end
    |> rest
  end

  defp prewalk(code), do: code

  defp rest?({:&, _, [{:rest, _, a}]}) when is_atom(a), do: true
  defp rest?([{:&, _, [{:rest, _, a}]}]) when is_atom(a), do: true
  defp rest?(_), do: false

  defp rest({f, meta, args}) do
    {args, rest} = args |> Enum.split_while(&(!rest?(&1)))
    rest = rest |> Stream.chunk_by(&rest?/1) |> Enum.reject(&rest?/1)
    {f, meta, args ++ rest}
  end
end
