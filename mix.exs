defmodule Mix.Tasks.Compile.Nif do
  def run(_) do
    {result, _error_code} = System.cmd("make", ["priv/native.so"], stderr_to_stdout: true)
    IO.binwrite(result)
    :ok
  end
end

defmodule Wabt.MixProject do
  use Mix.Project

  def project do
    [
      app: :wabt,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      compilers: [:nif, :elixir, :app],
      aliases: ["compile.erlang", "run"],
      deps: deps(),
      source_url: "https://github.com/viniarck/wabt-ex",
      homepage_url: "https://github.com/viniarck/wabt-ex",
      docs: [
        main: "Wabt",
        extras: ["README.md"]
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
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
