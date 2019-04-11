defmodule Islands.State.MixProject do
  use Mix.Project

  def project do
    [
      app: :islands_state,
      version: "0.1.1",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      name: "Islands State",
      source_url: source_url(),
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp source_url do
    "https://github.com/RaymondLoranger/islands_state"
  end

  defp description do
    """
    Implements a state machine for the Game of Islands.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "config/persist*.exs"],
      maintainers: ["Raymond Loranger"],
      licenses: ["MIT"],
      links: %{"GitHub" => source_url()}
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
      {:mix_tasks,
       github: "RaymondLoranger/mix_tasks", only: :dev, runtime: false},
      {:poison, "~> 4.0"},
      {:jason, "~> 1.0"},
      {:persist_config, "~> 0.1"},
      {:islands_player_id, "~> 0.1"},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end
end
