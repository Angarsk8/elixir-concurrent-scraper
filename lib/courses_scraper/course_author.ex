defmodule CourseAuthor do
  @moduledoc """
  Provides a set of functions to crawl the data of a course's author.
  It brings the ability	to build a struct with the needed information about the author.

  ## Example
      iex> author_tree = <some_nested_tree_object>
      <some_nested_tree_object>
      iex> CourseAuthor.build_author_struct(author_tree)
      %CourseAuthor{
        name: "Rob Percival",
        twitter: "https://twitter.com/techedrob",
        facebook: "https://www.facebook.com/rpcodestars"
        googleplus: "none",
        linkedin: "none",
        youtube: "https://www.youtube.com/user/robpercival"
      }
  """

  import Floki, only: [find: 2, text: 2, attribute: 2]

  @type t :: %CourseAuthor{
    name:       String.t,
    twitter:    String.t,
    googleplus: String.t,
    linkedin:   String.t,
    youtube:    String.t
  }

  @doc """
  Defines the fixed structure of an author of a course.
  """
  defstruct(
    name:       "",
    twitter:    "",
    facebook:   "",
    googleplus: "",
    linkedin:   "",
    youtube:    ""
  )

  @doc """
  Parses an HTML document tree that represents an author
  and find the name based on a CSS query string.
  """

  @spec get_author_name(author_tree, query) :: author_name when
    author_tree: Floki.Finder.html_tree,
    query:       String.t,
    author_name: String.t

  def get_author_name(author_tree, query) do
    author_tree
    |> find(query)
    |> text(deep: false)
    |> String.strip()
  end

  @doc """
  Parses an HTML document tree that represents an author
  and pattern match against a CSS query string to find his
  social media contact link.
  """

  @spec get_contact_link(author_tree, keyword) :: contact_link when
    author_tree:  Floki.Finder.html_tree,
    keyword:      String.t,
    contact_link: String.t

  def get_contact_link(author_tree, keyword) do
    selector = "a[href*=#{keyword}]"
    case find(author_tree, selector) do
      []     ->
        "none"
      result ->
        attribute(result, "href")
        |> hd()
    end
  end

  @doc """
  Build a struct that identifies an author of a course
  based on the HTML document tree passed as argument.
  """

  @spec build_author_struct(author_tree) :: course_author when
    author_tree:   Floki.Finder.html_tree,
    course_author: CourseAuthor.t

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
