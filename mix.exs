defmodule MakeupDiff.MixProject do
  use Mix.Project

  def project do
    [
      app: :makeup_diff,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Package
      package: package(),
      description: description(),
      docs: [
        main: "readme",
        extras: [
          "README.md"
        ]
      ]
    ]
  end

  defp description do
    """
    Diff lexer for the Makeup syntax highlighter.
    """
  end

  defp package do
    [
      name: :makeup_diff,
      licenses: ["MIT"],
      maintainers: ["Parker Selbert <parker@sorentwo.com>"],
      links: %{"GitHub" => "https://github.com/elixir-makeup/makeup_diff"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Makeup.Lexers.DiffLexer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:makeup, "~> 1.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end
end
