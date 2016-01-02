defmodule CoursesScraper.DocumentFetcher do

	require Logger

	@user_agent [{"User-agent", "Andres andresa.garciah621@gmail.com"}]
	@udemy_url Application.get_env :courses_scraper, :udemy_url

	def fetch(course_path) do
		build_course_url(course_path)
		|> HTTPoison.get(@user_agent, [recv_timeout: :infinity])
		|> handle_response(course_path)
	end

	defp build_course_url(course_path) do
		"#{@udemy_url}/#{course_path}/"
	end

	defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}, path) do
		Logger.info "Succesful response: /#{path}/"
		{:ok, body}
	end

	defp handle_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}, path) do
		Logger.error "Error: Response returned #{status_code} /#{path}/"
		{:not_useful, body}
	end

	defp handle_response({:error, %HTTPoison.Error{reason: reason}}, path) do
		Logger.error "Error: #{reason} /#{path}/"
		{:error, reason}
	end
end