defmodule Fluent.Mixfile do
  use Mix.Project

  def project do
    [app: :fluent,
      version: "0.0.1",
      deps: deps]
  end

  def application do
    []
  end

  defp deps do
    [{:msgpax, "~> 0.8"}]
  end
end
