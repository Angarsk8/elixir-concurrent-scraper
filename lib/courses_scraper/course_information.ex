defmodule CourseData do

	import Floki, only: [find: 2, text: 2, attribute: 2]
	import CourseAuthor, only: [build_author_struct: 1]

	defstruct source: "Udemy", url: "", category: "", subcategory: "", topic: "",
	 		 			authors: [], enrolled: 0, rating: 0, average_rating: 0, price: 0

	def extract_data({:ok, body}), do: build_course_struct(body)
	def extract_data(_), do: {:error, :to_be_discarded}

	defp build_course_struct(doc) do
		[category, subcategory] = get_category(doc, "span.cats a")
		[rating, enrolled] = get_enrolled(doc, ".enrolled span.rate-count")

		%CourseData{
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

	defp get_category(doc, query) do
		case find(doc, query) do
			[] -> ["Unknown", "Unknown"]
			[{_, _, [category]}, {_, _, [subcategory]}] -> 
				[String.strip(category), String.strip(subcategory)]
		end
	end

	defp get_topic(doc, query) do
		doc  
		|> find(query) 
		|> text(deep: false) 
		|> String.strip
	end

	defp get_enrolled(doc, query) do
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

	defp get_average_rating(doc, query) do
		case find(doc, query) do
			[]     -> 0.0
			result -> 
				result 
				|> text(deep: false) 
				|> String.strip 
				|> String.to_float
		end
	end

	defp get_price(doc, query) do
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

	defp get_authors(doc, query) do
		doc
		|> find(query)
		|> Enum.map(fn author ->
			build_author_struct(author)
		end)
	end

end