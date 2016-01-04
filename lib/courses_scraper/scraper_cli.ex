defmodule CoursesScraper.CLI do

	@output_dir Application.get_env :courses_scraper, :output_dir
	@output_file Application.get_env :courses_scraper, :output_file

	require Logger

	import CoursesScraper.DocumentFetcher, only: [fetch: 1]
	import CourseData, only: [build_course_struct: 1]

	@moduledoc """
	Defines a command line tool to parse, fetch and process the data from some Udemy courses's sites
	"""

	@doc """
	This is the function that wil be called and run by the escript executable.
	This function uses the Erlang's `:timer.tc` function to measure the execution
	time of the `run` function defined in this Module. Finally it logs the time
	alongside some description. 
	"""
	def main(argv) do
		{ time, _ } = :timer.tc CoursesScraper.CLI, :run, [argv]
		Logger.info "The overall processing took #{div(time, 60_000_000)} minutes (#{time} microseconds) to complete"
	end

	@doc """
	This function runs the program based on the arguments passed from the command line.
	This describes the flow of execution and transformation of the data. First, it parses 
	the arguments from the command line, then it reads the file where the user has indicated
	the courses paths are located at, and then process those paths to get the courses information
	"""
	def run(argv) do
		argv
			|> parse_args
			|> read_file_with_paths
			|> process
	end

	@doc """
	This function reads and parses the arguments passed from the command line
	and pattern match against the result to decide about the execution flow of the program.
	We use the Elixir built in parser module (OptionParser) to parse the data and also define
	some switches to help the user to use the CLI and some aliases to improve the experience
	of using it.
	"""
	def parse_args(argv) do
		parse = OptionParser.parse argv, switches: [help: :boolean], aliases: [h: :help]
		case parse do
			{[help: true], [], []} -> :help
			{_, [path_to_file_with_paths] , _} -> path_to_file_with_paths
			_ -> :help
		end
	end

	@doc """
	Read the file specifed in the path given as argument.

	* This function is executed when the parser returns a signal indicating help.
	It prints a message to the console and halts the system with a status of 0.

	* This function takes the name of the file provided from the CLI and reads
	it to get the data from it as an string and then splits it into an Elixir List.
	We perform a sane validation in the middle to ensure that the file was read succesfuly.
	"""
	def read_file_with_paths(:help) do
		IO.puts """
		Usage: courses_scraper <file_with_list_of_paths>
		"""
		System.halt 0
	end

	def read_file_with_paths(path_to_file_with_paths) do
		path_to_file_with_paths
			|> File.read
			|> handle_file_reading
			|> String.split 
	end

	@doc """
	Handles the reading process of a file.

	* This function is resposible for handling the reading process. If it success it returns 
	the string resulting from reading the file.

	*	This function is responsible for handling a posible failure in the reading process.
	If it fails it sumply prints a message to the console and halts the system with a status of 0.
	"""
	def handle_file_reading({:ok, string_of_paths}), do: string_of_paths
	def handle_file_reading({:error, reason}) do
		IO.puts """
		Error: The file failed the reading process (#{reason})
		"""
		System.halt 0
	end

	@doc """
	This function is responsible for processing the whole list of paths. This transforms step by
	step the data and finally writes the result into an output file. 
	"""
	def process(list_of_paths) do

		create_output_environment(@output_dir, @output_file)

			list_of_paths
			|> parallel_map_functions([
				&fetch/1,
				&build_course_struct/1,
				&Poison.encode!/1,
				&:jsx.prettify/1,
				&write_data_to_output_file/1
			])
	end

	@doc """
	This function creates the output location where the courses's information will be stored.
	If the file does exist already, it will simply clear it out for the next write.
	"""
	def create_output_environment(dir, file) do
		full_relative_path = "#{dir}/#{file}"
		case File.exists?(full_relative_path) do
			false -> 
				File.mkdir dir
				File.touch full_relative_path
			true -> 
				File.write full_relative_path, ""
		end
	end

	@doc """
	This function palallelizes the whole process. It gets a list of paths and a list of functions
	to be applied to each path. It basically maps a collection into a list of spawned concurrent
	processes, where each process is responsible for eventually sending a message to the current process
	with the processed data. That means, that there will be as many processes as paths to be requested
	in the list of paths. Once all the processes have been spawned, we just wait for the messages to come.
	"""
	def parallel_map_functions(collection, list_of_functions) do
		me = self
		collection
			|> Enum.map(fn el -> 
				spawn fn -> 
					send me, { self, list_of_functions |> Enum.reduce(el, & &1.(&2)) }
				end
			end)
			|> Enum.map(fn pid ->
				receive do
					{ ^pid, data } -> data
				end
			end)
	end

	@doc """
	this function appends the data passed as argument into the output file where the courses's
	information will be stored.
	"""
	def write_data_to_output_file(data) do
 		File.write "#{@output_dir}/#{@output_file}", data <> ",\n", [:append]
	end

end
