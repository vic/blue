defmodule Blue.MixProject do
  use Mix.Project

  def project do
    [
      app: :blue,
      version: "0.1.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "BLUE LISP",
      description: "Minimalist LISP abusing Elixir block syntax",
      package: package(),
      docs: [
        main: "Blue"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp package do
    [
      maintainers: ["Victor Borja <vborja@apache.org>"],
      licenses: ["Apache-2"],
      links: %{"GitHub" => "https://github.com/vic/blue"}
    ]
  end
end
