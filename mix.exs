defmodule Perudox.Mixfile do
  @moduledoc """
  """

  use Mix.Project

  def project do
    [
      app: :perudox,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      applications: [:logger],
      mod: {Perudox, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev},
      {:credo, "~> 0.4", only: :dev},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:dialyxir, "~> 0.4", only: :dev, runtime: false},

      {:faker, github: "igas/faker", override: true, only: ~w(dev test)a},
      {:blacksmith, "~> 0.1", only: ~w(dev test)a},
      {:excoveralls, "~> 0.5", only: ~w(dev test)a}
    ]
  end

  defp package do
    [
      name: :perudox,
      files: ~w(config lib test mix.exs README*),
      maintainers: ["Pierre Martin"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/hickscorp/perudox"}
    ]
  end

  defp description do
    """
    An implementation of the Perudo / Dudo / Pirate's Dice game written in Elixir.
    """
  end
end
