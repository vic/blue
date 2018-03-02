defmodule Blue do
  @moduledoc File.read!(Path.expand("../README.md", __DIR__))
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
      :error when head == :pipe -> reduce([:|>] ++ rest)
      :error when head == :reduce -> reduce(rest)
      :error when is_atom(head) -> {head, meta, rest}
      :error -> {{:., meta, [head]}, meta, rest}
    end
    |> rest
  end

  defp prewalk(code), do: code

  defp reduce([fun | rest]), do: Enum.reduce(rest, fn a, b -> {fun, [], [b, a]} end)

  defp rest?({:&, _, [{:rest, _, a}]}) when is_atom(a), do: true
  defp rest?([{:&, _, [{:rest, _, a}]}]) when is_atom(a), do: true
  defp rest?(_), do: false

  defp rest({f, meta, args}) do
    {args, rest} = args |> Enum.split_while(&(!rest?(&1)))
    rest = rest |> Stream.chunk_by(&rest?/1) |> Enum.reject(&rest?/1)
    {f, meta, args ++ rest}
  end
end
