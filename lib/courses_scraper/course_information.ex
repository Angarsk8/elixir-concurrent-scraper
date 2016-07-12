defmodule CourseData do
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

  import Floki, only: [find: 2, text: 2, attribute: 2]
  import CourseAuthor, only: [build_author_struct: 1]

  @type authors       :: [CourseAuthor.t]
  @type doc           :: String.t
  @type query         :: String.t
  @type category_data :: {String.t, String.t}

  @type t :: %CourseData{
    url:            String.t,
    topic:          String.t,
    subcategory:    String.t,
    source:         String.t,
    rating:         non_neg_integer,
    price:          non_neg_integer,
    enrolled:       non_neg_integer,
    category:       String.t,
    average_rating: float,
    authors:        authors
  }

  @doc """
  Defines the fixed structure of a course.
  """
  defstruct(
    source:        "Udemy",
    url:           "",
    category:      "",
    subcategory:   "",
    topic:         "",
    authors:       [],
    enrolled:       0,
    rating:         0,
    average_rating: 0,
    price:          0
  )

  @doc """
  Builds the structure of an individual Udemy course. It parses the data
  from an HTTP response and scrape the body to extract the needed data.
  """

  @spec build_course_struct(response) :: CourseData.t | no_return when
    response: CoursesScraper.DocumentFetcher.response

  def build_course_struct({:ok, doc, path}) do
    category_data = get_category_data(doc, "span.cats a")
    %CourseData{
      url: CoursesScraper.DocumentFetcher.build_course_url(path),
      category: get_category(category_data),
      subcategory: get_subcategory(category_data),
      topic: get_topic(doc, "h1.course-title"),
      authors: get_authors(doc, "[id=instructor]"),
      enrolled: get_enrolled(doc, ".rate-count"),
      rating: get_rating(doc, "[itemprop=ratingCount]"),
      average_rating: get_average_rating(doc, "[itemprop=ratingValue]"),
      price: get_price(doc, "meta[property='udemy_com:price']")
    }
  rescue
    _ ->
      exit({:bad_data, path})
  end
  def build_course_struct({_, _, path}), do: exit({:bad_response, path})

  @doc """
  Get the course category from the HTML document of the course's website,
  based on a CSS query, and pattern match against the result to return
  the proper value.
  """

  @spec get_category_data(doc, query) :: category_data
  def get_category_data(doc, query) do
    case find(doc, query) do
      []  ->
        {"Unknown", "Unknown"}
      [{_, _, [category]}, {_, _, [subcategory]}] ->
        {String.strip(category), String.strip(subcategory)}
    end
  end

  @spec get_category(category_data) :: category when category: String.t
  def get_category({category, _}), do: category

  @spec get_category(category_data) :: subcategory when subcategory: String.t
  def get_subcategory({_, subcategory}), do: subcategory

  @doc """
  Get the course topic from the HTML document of the course's website,
  based on a CSS query.
  """

  @spec get_topic(doc, query) :: topic when topic: String.t
  def get_topic(doc, query) do
    doc
    |> find(query)
    |> text(deep: false)
    |> String.strip()
  end

  @doc """
  Get the enrolled information subtree from the course's HTML document
  and perform a `Regex.scan` against a fixed regular expression, in order
  to find the number of enrolled students.
  """

  @spec get_enrolled(doc, query) :: enrolled when enrolled: non_neg_integer
  def get_enrolled(doc, query) do
    doc
    |> find(query)
    |> text(deep: false)
    |> String.strip()
    |> (&Regex.scan(~r/[-+]?\d*\,\d+|\d+/, &1)).()
    |> List.flatten()
    |> Enum.reverse()
    |> hd()
    |> String.replace(",", "")
    |> String.to_integer()
  end

  @doc """
  Get the rating (amount of students who rated the course) from the HTML document of the course's website,
  based on a CSS query
  """

  @spec get_rating(doc, query) :: rating when rating: non_neg_integer
  def get_rating(doc, query) do
    doc
    |> find(query)
    |> attribute("content")
    |> hd()
    |> String.to_integer()
  end

  @doc """
  Get the average rating from the HTML document of the course's website,
  based on a CSS query
  """

  @spec get_average_rating(doc, query) :: avg_rating when avg_rating: float
  def get_average_rating(doc, query) do
    doc
    |> find(query)
    |> attribute("content")
    |> hd()
    |> String.to_float()
  end

  @doc """
  Get the price from the HTML document of the course's website,
  based on a CSS query. This time the price was present in the head
  of the document as a metada field, so I applied some extra steps
  of transformations to get back the proper result.
  """

  @spec get_price(doc, query) :: price when price: integer
  def get_price(doc, query) do
    str_price =
      doc
      |> find(query)
      |> attribute("content")
      |> hd()
      |> String.replace(~r/\D/, "")

    case str_price do
      ""    ->
        0
      str_price ->
        String.to_integer(str_price)
    end
  end

  @doc """
  Get the list of authors from the HTML document of the course's
  website, based on a CSS query. This time `the build_author_struct`
  function from the `CourseAuhor` module is used to take care of the
  specific author data.
  """

  @spec get_authors(doc, query) :: authors
  def get_authors(doc, query) do
    doc
    |> find(query)
    |> Enum.map(&build_author_struct/1)
  end
end
