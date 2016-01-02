defmodule CourseAuthor do

	import Floki, only: [find: 2, text: 2, attribute: 2]

	defstruct name: "", twitter: "", facebook: "", googleplus: "", linkedin: "", youtube: ""

	defp get_author_name(author_tree, query) do
		author_tree
		|> find(query)
		|> text(deep: false)
		|> String.strip
	end

	defp get_contact_link(author_tree, keyword) do
		selector = "a[href*=#{keyword}]"
		case find(author_tree, selector) do
			[] -> "none"
			result -> hd attribute(result, "href")
		end
	end


	def build_author_struct(author_tree) do
		%CourseAuthor{
				name: get_author_name(author_tree, "a.ins-name"),
				twitter: get_contact_link(author_tree, "twitter"),
				facebook: get_contact_link(author_tree, "facebook"),
				googleplus: get_contact_link(author_tree, "googleplus"),
				linkedin: get_contact_link(author_tree, "linkedin"),
				youtube: get_contact_link(author_tree, "youtube")
			}
	end
end