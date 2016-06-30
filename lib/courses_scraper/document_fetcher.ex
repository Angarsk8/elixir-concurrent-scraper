defmodule CoursesScraper.DocumentFetcher do
  @moduledoc """
  provides a set of high level functions to fetch the data from a website
  and handle the result into a meaningful value.
  """

  require Logger

  @udemy_url Application.get_env :courses_scraper, :udemy_url

  @type path      :: String.t
  @type signal    :: :ok | :not_useful | :error
  @type body      :: String.t
  @type info      :: body | atom | :problem
  @type response  :: {signal, info, path}
  @type http_resp :: {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
                     {:error, HTTPoison.Error.t}

  @doc """
  Fetch the data of an Udemy course's website using the HTTPoison library to simulate
  an HTTP client, and handle the result to return some meaningful data to the caller
  of the function. This function is embedded into a `try do - rescue` block because the
  `HTTPoison` library has a bug that limits a client to make "too many" requests.
  """

  @spec fetch(path) :: response

  def fetch(course_path) do
    build_course_url(course_path)
    |> HTTPoison.get([], [recv_timeout: :infinity, timeout: :infinity])
    |> handle_response(course_path)
  rescue
    error ->
      Logger.error "Error: #{inspect error} in /#{course_path}/ | Trying Again"
      fetch(course_path)
  end

  @doc """
  Build the full URL to reach the course's website
  """

  @spec build_course_url(path) :: url when url: String.t

  def build_course_url(course_path), do: "#{@udemy_url}/#{course_path}/"

  # Handle the response that comes from an HTTP GET request
  #
  # * Handle a succesfull response with the form of `{:ok, %HTTPoison.Response{status_code: 200, body: body}`,
  # transparently log a message to the console and return a tuple with an atom indicating the success,
  # the body of the response and the path requested
  #
  # * Handle an useless response and return some meaningful data to the caller.
  #
  # * Handle an erroneous response and return some meaningful data to the caller.

  @spec handle_response(http_resp, path) :: response

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}, path) do
    Logger.info "Succesful response: /#{path}/"
    {:ok, body, path}
  end
  defp handle_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}, path) do
    Logger.error "Error: Response returned #{status_code} /#{path}/"
    {:not_useful, body, path}
  end
  defp handle_response({:error, %HTTPoison.Error{reason: reason}}, path) do
    Logger.error "Error: #{reason} /#{path}/"
    {:error, reason, path}
  end
  defp handle_response(_, path) do
    Logger.error "Error: Something happened processing /#{path}/"
    {:error, :problem, path}
  end
end
