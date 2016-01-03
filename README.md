## Udemy Courses Scraping (Elixir/Mix Concurrent Version)

Make sure you have Erlang and [Elixir](http://elixir-lang.org/install.html) installed before you follow the next steps. If you are using OSX, just run `brew install elixir` in a terminal prompt and it will install both Erlang and Elixir for you. 

### Usage

To use this program you have to install the required depencies listed in the `mix.exs` file, specifically in the `deps` function. To install the dependencies just run `$ mix deps.get` in a terminal prompt and it will download all the files into a `deps` folder at the root level. Elixir Mix projects are in some way like Node projects (If you are familiar with Node), where basically all of yout project's dependencies live inside the project's directory. 

Once you have installed all of the dependencies, execute the Mix task `$ mix escript.build` to compile the source code and all of its dependencies into bytecode that can be run and interpreted by the Erlang VM. It basically creates a command line executable that you can use to run the program in UNIX based platforms that have Erlang installed. 

The purpose of this program is to scrape concurrently (separate processes) the data from some Udemy courses pages and retrieve the relevant data as a JSON document (see sample output below). This version proved to be upto ***6x*** times faster than the non concurrent version of this program and upto ***10x*** faster than a [Ruby](https://github.com/Angarsk8/udemy_courses_scraping) version of this program, in a couple of tests that I did in my computer. I haven't done any proper benchmark to test that better, but I will include one in the future. 

To execute the program you have to run the following command in a shell prompt:

```
$ ./courses_scraper <path_to_the_file_with_courses_paths>
```

Where the `<path_to_the_file_with_courses_paths>` is a file containing the paths associated with the Udemy courses to be scraped. The file must have the following shape in order to work.

```
 curso-completo-desarrollador-ios-15-apps android-basico
 curso-de-desarrollo-de-apps-para-ios-9 desarrollo-ios-con-swift 
 aprende-wordpress-sin-conocimientos-previos creando-paginas-web-con-html5-css3-y-bootstrap-3
 programacion-para-emprendedores ...
```

That means, the file must contains the paths that yield to their respective Udemy websites separated by one or more spaces. 

### Sample Outputs 

* ***output/courses.json***:

```javascript
[
    {
      "source": "Udemy",
      "url": "https://www.udemy.com/curso-completo-desarrollador-ios-15-apps/",
      "category": "Programación",
      "subcategory": "Aplicaciones Móviles",
      "topic": "iOS 8 y Swift Completo: Aprende creando 15 Apps reales",
      "authors": [
        {
          "name": "Rob Percival",
          "twitter": "https://twitter.com/techedrob",
          "facebook": "https://www.facebook.com/rpcodestars",
          "googleplus": "https://plus.google.com/112310006632536121434?rel=author",
          "linkedin": "none",
          "youtube": "https://www.youtube.com/user/robpercival",
          "website": "http://www.completewebdevelopercourse.com"
        },
        {
          "name": "KeepCoding Online",
          "twitter": "https://twitter.com/@KeepCoding_es",
          "facebook": "https://www.facebook.com/pages/Agbotraining/463644126986852",
          "googleplus": "https://plus.google.com/https://plus.google.com/u/1/b/104277667088859577707/+KeepCoding/posts?rel=author",
          "linkedin": "https://linkedin.com/company/keepcoding",
          "youtube": "https://www.youtube.com/https://www.youtube.com/channel/UCz-oGx94gqD1lICJQZGniLA",
          "website": "http://keepcoding.io/es/"
        },
        {
          "name": "Juan José  Ramírez",
          "twitter": "none",
          "facebook": "none",
          "googleplus": "none",
          "linkedin": "none",
          "youtube": "none",
          "website": "http://agbo.biz/tech/curso-android-basico/"
        }
      ],
      "enrolled": 743,
      "rating": 28,
      "average_rating": 4.9,
      "price": 205
    },
    {
      "source": "Udemy",
      "url": "https://www.udemy.com/android-basico/",
      "category": "Development",
      "subcategory": "Mobile Apps",
      "topic": "Android básico",
      "authors": [
        {
          "name": "José Luján",
          "twitter": "https://twitter.com/josedlujan",
          "facebook": "https://www.facebook.com/josedlujan",
          "googleplus": "https://plus.google.com/103871608091491576854?rel=author",
          "linkedin": "https://linkedin.com/in/josedlujan/",
          "youtube": "https://www.youtube.com/josedlujan1",
          "website": "http://josedlujan.com"
        }
      ],
      "enrolled": 4223,
      "rating": 75,
      "average_rating": 4.7,
      "price": 20
    },
    ...
]
```
