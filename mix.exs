defmodule CoursesScraper.Mixfile do
  use Mix.Project

  def project do
    [
      app: :courses_scraper,
      version: "0.0.1",
      elixir: "~> 1.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      name: "Courses Scrapper",
      source_url: "https://github.com/angarsk8/elixir_courses_scraper",
      escript: escript,
      deps: deps
    ]
  end

  def application do
   [
     applications: [
       :logger,
       :httpoison,
       :floki,
       :poison,
       :jsx
     ]
   ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.0"},
      {:floki, "~> 0.7.1"},
      {:poison, "~> 1.5"},
      {:jsx, "~> 2.8"},
      {:ex_doc, "~> 0.12", only: :dev},
      {:cmark, "~> 0.6", only: :dev}
    ]
  end

  defp escript do
    [
      main_module: CoursesScraper.CLI
    ]
  end
end
