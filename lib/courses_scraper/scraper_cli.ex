defmodule CoursesScraper.CLI do

   @output_dir   Application.get_env :courses_scraper, :output_dir
   @output_file  Application.get_env :courses_scraper, :output_file
   @cli_switches Application.get_env :cli_switches, :output_file
   @cli_aliases  Application.get_env :cli_aliases, :output_file
   
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
      { time_in_microseconds, _ } = :timer.tc(CoursesScraper.CLI, :run, [argv]) 
      time_is_seconds = div(time_in_microseconds, 1_000_000)
      Logger.info "The overall processing took #{time_is_seconds} sec to complete"
   end
   
   @doc """
   This function runs the program based on the arguments passed from the command line.
   This describes the flow of execution and transformation of the data. First, it parses 
   the arguments from the command line, then it handles those arguments, then checks whether the
   the file with the paths exists or not, then it reads the paths from the file, and finally process 
   those paths to get the courses information.
   """
   def run(argv) do
      argv
         |> parse_args
         |> handle_args
         |> exists_file_with_paths?
         |> read_file_with_paths
         |> process
   end
   
   # This function reads and parses the arguments passed from the command line
   # and pattern match against the result to decide about the execution flow of the program.
   # We use the Elixir built in parser module (OptionParser) to parse the data and also define
   # some switches to help the user to use the CLI and some aliases to improve the experience
   # of using it.
   defp parse_args(argv) do
      parse = OptionParser.parse argv, switches: @cli_switches, aliases: @cli_aliases
      case parse do
         {[help: true], [], []}                       -> :help
         {[all: true], [path_to_file_with_paths], []} -> {:all, path_to_file_with_paths}
         {_, [path_to_file_with_paths] , _}           -> {:all, path_to_file_with_paths}
         {[], [path_to_file_with_paths, items], []}   -> {safe_cast_to_int(items), path_to_file_with_paths}
         _                                            -> :help
      end
   end
   
   # This function safely casts an string into a integer within the context of this project
   defp safe_cast_to_int(string) do
      try do
         String.to_integer(string)
      rescue
         e -> 
            IO.puts """
            Error: Expected a number a received a string instead "#{e.message}"
            """
            System.halt 0
      end
   end
   
   # This function handles the arguments parsed from the command line.
   # 
   # * This function is executed when the parser returns a signal indicating help.
   # It prints a message to the console and halts the system with a status of 0.
   # 
   # * This fucntions is executed when the parser returns a signal different to help.
   # It just returns the parsed arguments.
   defp handle_args(:help) do
      IO.puts """
      Usage: courses_scraper <file_with_list_of_paths> [<number_of_paths>] [--help] [--all]
      
      Options:
      -h, --help     print help message, showing details about the usage of this tools   
      -a, --all      flag to scrape all the paths inside the file passed as argument
      """
      System.halt 0
   end
   defp handle_args(parsed_args), do: parsed_args
   
   # This function verifies if the file passed as argument to the command line exists or not.
   defp exists_file_with_paths?(parsed_args = {_, path_to_file_with_paths}) do
      case File.exists?(path_to_file_with_paths) do
         false ->
            IO.puts "The file \"#{path_to_file_with_paths}\" does not exist!!"
            System.halt 0
         true  -> 
            parsed_args
      end
   end
   
   # Read the file specifed in the path given as argument.
   # 
   # * This function takes the name of the file provided from the CLI and reads
   # it to get the data from it as an string and then splits it into an Elixir List, finally it
   # filter that list of paths based on the number passed as argument to the command line.
   # We perform a sane validation in the middle to ensure that the file was read succesfuly.
   defp read_file_with_paths({option, path_to_file_with_paths}) do
      path_to_file_with_paths
         |> File.read
         |> handle_file_reading
         |> String.split
         |> filter_list_of_paths(option)
   end
   
   
   # Handles the reading process of a file.
   # 
   # * This function is resposible for handling the reading process. If it success it returns 
   # the string resulting from reading the file.
   # 
   # *	This function is responsible for handling a posible failure in the reading process.
   # If it fails it sumply prints a message to the console and halts the system with a status of 0.
   defp handle_file_reading({:ok, string_of_paths}), do: string_of_paths
   defp handle_file_reading({:error, reason}) do
      IO.puts """
      Error: The file failed the reading process (#{reason})
      """
      System.halt 0
   end
   
   # This function filters that list of paths based on the number passed as argument
   # to the command line.
   # 
   # * If the command line returns a signal of :all the it just returns the same list of paths.
   # 
   # * If the command line returns a signal different to :all, it filters the list based on the 
   # number given as argument to the command. 
   defp filter_list_of_paths(list_of_paths, :all), do: list_of_paths
   defp filter_list_of_paths(list_of_paths, items), do: list_of_paths |> Enum.take(items)
   
   # This function is responsible for processing the whole list of paths. This transforms step by
   # step the data and finally writes the result into an output file. 
   defp process(list_of_paths) do
   
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
   
   # This function creates the output location where the courses's information will be stored.
   # If the file does exist already, it will simply clear it out for the next write.
   defp create_output_environment(dir, file) do
      full_relative_path = "#{dir}/#{file}"
      case File.exists?(full_relative_path) do
         false -> 
            File.mkdir dir
            File.touch full_relative_path
         true  -> 
            File.write full_relative_path, ""
      end
   end
   
   # This function palallelizes the whole process. It gets a list of paths and a list of functions
   # to be applied to each path. It basically maps a collection into a list of spawned concurrent
   # processes, where each process is responsible for eventually sending a message to the current process
   # with the processed data. That means, that there will be as many processes as paths to be requested
   # in the list of paths. Once all the processes have been spawned, we just wait for the messages to come.
   defp parallel_map_functions(collection, list_of_functions) do

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
   
   # this function appends the data passed as argument into the output file where the courses's
   # information will be stored.
   defp write_data_to_output_file(data) do
      File.write "#{@output_dir}/#{@output_file}", data <> ",\n", [:append]
   end

end
