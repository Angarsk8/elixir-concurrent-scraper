defmodule CoursesScraper.CLI do

	@output_dir Application.get_env :courses_scraper, :output_dir
	@output_file Application.get_env :courses_scraper, :output_file

	require Logger

	import CoursesScraper.DocumentFetcher, only: [fetch: 1]
	import CourseData, only: [extract_data: 1]

	def main(argv) do
		argv
		|> parse_args
		|> read_file_with_paths
		|> process
	end

	defp parse_args(argv) do
		parse = OptionParser.parse argv, switches: [help: :boolean], aliases: [h: :help]
		case parse do
			{[help: true], [], []} -> :help
			{_, [path_to_file_with_paths] , _} -> path_to_file_with_paths
			_ -> :help
		end
	end

	def read_file_with_paths(path_to_file_with_paths) do
		path_to_file_with_paths
		|> File.read
		|> handle_file_reading
  	|> String.split 
	end

	def handle_file_reading({:ok, string_of_paths}), do: string_of_paths
	def handle_file_reading({:error, reason}) do
		IO.puts """
		Error: The file failed the reading process (#{reason})
		"""
		System.halt 0
	end

	defp process(:help) do
		IO.puts """
		Usage: courses_scraper <file_with_list_of_paths>
		"""
		System.halt 0
	end

	defp process(list_of_paths) do

		create_output_environment(@output_dir, @output_file)

		list_of_paths
		|> parallel_process_list_of_paths
		|> Enum.each(fn data ->
			File.write "#{@output_dir}/#{@output_file}", data, [:append]
		end)

		Logger.info "The process has finished succesfully"
	end

	defp create_output_environment(dir, file) do
		full_relative_path = "#{dir}/#{file}"
		case File.exists?(full_relative_path) do
			false -> 
				File.mkdir dir
				File.touch full_relative_path
			true -> 
				File.write full_relative_path, ""
		end
	end

	defp parallel_process_list_of_paths(list_of_paths) do
		me = self
		list_of_paths
		|> Enum.map(fn path -> 
			spawn fn -> send me, { self, parallel_process(path) } end
		end)
		|> Enum.map(fn pid ->
			receive do
				{ ^pid, data } -> data
			end
		end)
	end

	def parallel_process(path) do
		try do
			path 
				|> fetch 
				|> extract_data
				|> Poison.encode!
				|> :jsx.prettify
		rescue 
			_error -> Logger.error "Error: Processing data /#{path}/"
		end
	end
end
