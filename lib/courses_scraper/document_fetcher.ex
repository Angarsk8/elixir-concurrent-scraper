defmodule CoursesScraper.DocumentFetcher do

	require Logger

	@user_agent [{"User-agent", "Andres andresa.garciah621@gmail.com"}]
	@udemy_url Application.get_env :courses_scraper, :udemy_url

	@moduledoc """
	provides a set of high level functions to fetch the data from a website
	and handle the result into a meaningful value.
	"""

	@doc """
	Fetch the data of an Udemy course's website using the HTTPoison
	library to simulate an HTTP client, and handle the result to 
	return some meaningful data to the caller of the function.
	"""
	def fetch(course_path) do
		build_course_url(course_path)
		|> HTTPoison.get(@user_agent, [recv_timeout: :infinity])
		|> handle_response(course_path)
	end

	@doc """
	Build the full URL to reach the course's website
	"""
	def build_course_url(course_path) do
		"#{@udemy_url}/#{course_path}/"
	end

	@doc """
	Handle the response that comes from an HTTP GET request

	* Handle a succesfull response with the form of  `{:ok, %HTTPoison.Response{status_code: 200, body: body}`,
	transparently log a message to the console and return a tuple with an atom indicating the success,
	the body of the response and the path requested

	* Handle an useless response and return some meaningful data to the caller.

	* Handle an erroneous response and return some meaningful data to the caller.
	"""
	def handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}, path) do
		Logger.info "Succesful response: /#{path}/"
		{:ok, body, path}
	end

	def handle_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}, path) do
		Logger.error "Error: Response returned #{status_code} /#{path}/"
		{:not_useful, body, path}
	end

	def handle_response({:error, %HTTPoison.Error{reason: reason}}, path) do
		Logger.error "Error: #{reason} /#{path}/"
		{:error, reason, path}
	end
end