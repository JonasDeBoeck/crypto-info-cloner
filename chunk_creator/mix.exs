defmodule ChunkCreator.MixProject do
  use Mix.Project

  def project do
    [
      app: :chunk_creator,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ChunkCreator.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kafka_ex, "~> 0.11.0"},
      {:assignment_messages, git: "https://github.com/distributed-applications-2021/assignment-messages", branch: "main"},
      {:database_interaction,
       git: "https://github.com/distributed-applications-2021/assignment-database-interaction", branch: "main"},
       {:myxql, "~> 0.4.3"}
    ]
  end
end
