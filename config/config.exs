use Mix.Config

config :courses_scraper,
  udemy_url: "https://www.udemy.com",
  output_dir: "output/",
  output_file: "courses.json",
  cli_switches: [help: :boolean, all: :boolean],
  cli_aliases:  [h: :help, a: :all]

config :logger, compile_time_purge_level: :info

config :ex_doc, :markdown_processor, ExDoc.Markdown.Cmark
