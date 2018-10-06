defmodule RMQTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :rmqtest,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {RMQTest, []},
      applications: [:amqp],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 1.6", override: true},
      {:ranch_proxy_protocol, "~> 2.0", override: true},
      {:lager, "~> 3.6.6", override: true},
      {:amqp, "~> 1.0"},
      {:poison, "~> 3.1"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
