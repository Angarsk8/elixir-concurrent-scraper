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
  @type enrolled_data :: {non_neg_integer, rating}
  @type rating        :: 0..100
  @type category_data :: {String.t, String.t}

  @type t :: %CourseData{
    url: String.t,
    topic: String.t,
    subcategory: String.t,
    source: String.t,
    rating: rating,
    price: non_neg_integer,
    enrolled: non_neg_integer,
    category: String.t,
    average_rating: float,
    authors: authors
  }

  @doc """
  Defines the fixed structure of a course.
  """
  defstruct source: "Udemy", url: "", category: "", subcategory: "", topic: "",
            authors: [], enrolled: 0, rating: 0, average_rating: 0, price: 0

  @doc """
  Builds the structure of an individual Udemy course. It parses the data
  from an HTTP response and scrape the body to extract the needed data.
  """

  @spec build_course_struct(response) :: CourseData.t when
    response: CoursesScraper.DocumentFetcher.response

  def build_course_struct({:ok, doc, path}) do
    enrolled_data = get_enrolled_data(doc, ".enrolled span.rate-count")
    category_data = get_category_data(doc, "span.cats a")

    %CourseData{
      url: CoursesScraper.DocumentFetcher.build_course_url(path),
      category: get_category(category_data),
      subcategory: get_subcategory(category_data),
      topic: get_topic(doc, "h1.course-title"),
      authors: get_authors(doc, "[id=instructor]"),
      enrolled: get_enrolled(enrolled_data),
      rating: get_rating(enrolled_data),
      average_rating: get_average_rating(doc, ".average-rate"),
      price: get_price(doc, "meta[property='udemy_com:price']")
    }
  rescue
    _ ->
      exit({:bad_data, path})
  end
  def build_course_struct(_), do: %CourseData{}

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
  to find the rating and the number of enrolled students as a list.
  """

  @spec get_enrolled_data(doc, query) :: enrolled_data
  def get_enrolled_data(doc, query) do
    enrolled_info =
      doc
      |> find(query)
      |> text(deep: false)
      |> String.strip()

    ~r/[-+]?\d*\,\d+|\d+/
    |> Regex.scan(enrolled_info)
    |> Enum.map(fn [inf] ->
      inf |> String.replace(~r/\,+\d+/, "") |> String.to_integer
    end)
    |> :erlang.list_to_tuple()
  end

  @spec get_enrolled(enrolled_data) :: non_neg_integer
  def get_enrolled({enrolled, _}), do: enrolled

  @spec get_rating(enrolled_data) :: rating
  def get_rating({_, rating}), do: rating

  @doc """
  Get the average rating from the HTML document of the course's website,
  based on a CSS query and pattern match against the result to return
  the proper value
  """

  @spec get_average_rating(doc, query) :: avg_rating when avg_rating: float
  def get_average_rating(doc, query) do
    case find(doc, query) do
      []     ->
        0.0
      result ->
        result
        |> text(deep: false)
        |> String.strip()
        |> String.to_float()
    end
  end

  @doc """
  Get the price from the HTML document of the course's website,
  based on a CSS query. This time the price was present in the head
  of the document as a metada field, so I applied some extra steps
  of transformations to get back the proper result.
  """

  @spec get_price(doc, query) :: price when price: integer
  def get_price(doc, query) do
    price =
      doc
      |> find(query)
      |> attribute("content")
      |> hd()
      |> String.replace(~r/\D/, "")

    case price do
      ""    ->
        0
      price ->
        String.to_integer(price)
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
