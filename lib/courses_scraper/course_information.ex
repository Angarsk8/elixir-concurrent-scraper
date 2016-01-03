defmodule CourseData do

	import Floki, only: [find: 2, text: 2, attribute: 2]
	import CourseAuthor, only: [build_author_struct: 1]

	@moduledoc """
	Provides a set of functions to crawl the data from a course's HTML document.
	It brings the ability	to build a struct with the needed information about a course.

	## Example
		iex> {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get("https://www.udemy.com/android-basico/")
		{:ok, %HTTPoison.Response{status_code: 200, body: "..."}}
		iex> CourseData.extract_data({:ok, body, "android-basico"})
		%CourseData{
			url: "https://udemy.com/android-basico",
			topic: "Android básico",
			subcategory: "Mobile Apps",
			source: "Udemy",
			rating: 77,
			price: 20,
			enrolled: 4278,
			category: "Development",
			average_rating: 4.6,
			authors: [
				%CourseAuthor{
					youtube: "https://www.youtube.com/josedlujan1",
					twitter: "https://twitter.com/josedlujan",
					name: "José Luján",
					linkedin: "https://linkedin.com/in/josedlujan/",
					googleplus: "none",
					facebook: "https://www.facebook.com/josedlujan"
				}
			]
		}
	"""

	@doc """
	Defines the fixed structure of a course.
	"""
	defstruct source: "Udemy", url: "", category: "", subcategory: "", topic: "",
	 		 			authors: [], enrolled: 0, rating: 0, average_rating: 0, price: 0

	@doc """
	Parse the data from a HTTP response and crawl the body to extract the needed data.

	* Parse the data from a HTTP response and crawl the body to extract the needed data.
	This function relies in the `build_course_struct` function to build the structure.

	* Handle an erroneous HTTP response body and return a tuple with some meaningful values.
	"""
	def extract_data({:ok, body, path}), do: build_course_struct(body, path)
	def extract_data(_response), do: {:error, :to_be_discarded}

	@doc """
	Builds the structure of an individual Udemy course.
	"""
	def build_course_struct(doc, path) do
		[category, subcategory] = get_category(doc, "span.cats a")
		[rating, enrolled] = get_enrolled(doc, ".enrolled span.rate-count")

		%CourseData{
			url: CoursesScraper.DocumentFetcher.build_course_url(path),
			category: category,
			subcategory: subcategory,
			topic: get_topic(doc, "h1.course-title"),
			authors: get_authors(doc, "[id=instructor]"),
			enrolled: enrolled,
			rating: rating,
			average_rating: get_average_rating(doc, ".average-rate"),
			price: get_price(doc, "meta[property='udemy_com:price']")
		}
	end

	@doc """
	Get the course category from the HTML document of the course's website,
	based on a CSS query, and pattern match against the result to return
	the proper value.
	"""
	def get_category(doc, query) do
		case find(doc, query) do
			[] -> 
				["Unknown", "Unknown"]
			[{_, _, [category]}, {_, _, [subcategory]}] -> 
				for el <- [category, subcategory], do: String.strip el
		end
	end

	@doc """
	Get the course topic from the HTML document of the course's website,
	based on a CSS query.
	"""
	def get_topic(doc, query) do
		doc  
			|> find(query) 
			|> text(deep: false) 
			|> String.strip
	end

	@doc """
	Get the enrolled information subtree from the course's HTML document
	and perform a `Regex.scan` against a fixed regular expression, in order
	to find the rating and the number of enrolled students as a list.
	"""
	def get_enrolled(doc, query) do
		enrolled_info = doc 
			|> find(query)
			|> text(deep: false)
			|> String.strip

		~r/[-+]?\d*\,\d+|\d+/
			|> Regex.scan(enrolled_info)
			|> Enum.map(fn [inf] -> 
				inf |> String.replace(~r/\,+\d+/, "") |> String.to_integer
			end)
	end

	@doc """
	Get the average rating from the HTML document of the course's website,
	based on a CSS query and pattern match against the result to return
	the proper value
	"""
	def get_average_rating(doc, query) do
		case find(doc, query) do
			[]     -> 0.0
			result -> 
				result 
					|> text(deep: false) 
					|> String.strip 
					|> String.to_float
		end
	end

	@doc """
	Get the price from the HTML document of the course's website,
	based on a CSS query. This time the price was present in the head
	of the document as a metada field, so I applied some extra steps
	of transformations to get back the proper result.  
	"""
	def get_price(doc, query) do
		price = doc
			|> find(query)
			|> attribute("content")
			|> hd
			|> String.replace(~r/\D/, "")

		case price do
			"" -> 0
			price -> String.to_integer(price)
		end
	end

	@doc """
	Get the list of authors from the HTML document of the course's
	website, based on a CSS query. This time `the build_author_struct`
	function from the `CourseAuhor` module is used to take care of the
	specific author data.
	"""
	def get_authors(doc, query) do
		doc
			|> find(query)
			|> Enum.map(fn author ->
				build_author_struct(author)
			end)
	end

end