defmodule ClonerWorker.MixProject do
  use Mix.Project

  def project do
    [
      app: :cloner_worker,
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
      mod: {ClonerWorker.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kafka_ex, "~> 0.11.0"},
      {:assignment_messages,
       git: "https://github.com/distributed-applications-2021/assignment-messages", branch: "main"},
      {:tesla, "~> 1.4"},
      {:jason, "~> 1.2"}
    ]
  end
end
