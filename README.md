## Udemy Courses Scraper (Elixir/Mix Concurrent Version)

Make sure you have Erlang and [Elixir](http://elixir-lang.org/install.html) installed before you follow the next steps. If you are using OSX, just run `$ brew install elixir` and it will install both Erlang and Elixir for you. 

### Basic Usage

To execute this program, just run the following command:
```
$ ./courses_scraper <file_with_paths> [ <number_of_paths> | --all ] [--help]
```

where: 

* `./courses_scraper` is the actual executable program.
* `<file_with_paths>` is the file that contains the list of paths to be scraped in the Udemy website.
* `<number_of_paths>` is the number of paths you want to scrape from `<file_with_paths>`.
* `--all` is an option that you can use explicitely to scrape all the files from `<file_with_paths>`.
* `--help` is an option to ask for help, showing details about the usage of this tools.

### Sample Usage

```
$ ./courses_scraper courses_paths 5

20:31:48.869 [info]  Succesful response: /aprende-wordpress-sin-conocimientos-previos/
20:31:49.178 [info]  Succesful response: /android-basico/
20:31:49.642 [info]  Succesful response: /desarrollo-ios-con-swift/
20:31:49.671 [info]  Succesful response: /curso-completo-desarrollador-ios-15-apps/
20:31:49.884 [info]  Succesful response: /curso-de-desarrollo-de-apps-para-ios-9/

20:31:50.344 [info]  The overall processing took 3 sec to complete
```

***output/courses.json***:

```javascript
[
  {
    "url": "https://www.udemy.com/aprende-wordpress-sin-conocimientos-previos/",
    "topic": "Aprende Wordpress sin conocimientos previos y gana dinero",
    "subcategory": "Desarrollo Web",
    "source": "Udemy",
    "rating": 44,
    "price": 9,
    "enrolled": 2453,
    "category": "Programación",
    "average_rating": 4.6,
    "authors": [
      {
        "youtube": "none",
        "twitter": "https://twitter.com/oscarmartin",
        "name": "Oscar Martin",
        "linkedin": "none",
        "googleplus": "none",
        "facebook": "https://www.facebook.com/oscarmartinherrera"
      }
    ]
  },
  {
    "url": "https://www.udemy.com/android-basico/",
    "topic": "Android básico",
    "subcategory": "Mobile Apps",
    "source": "Udemy",
    "rating": 77,
    "price": 20,
    "enrolled": 4279,
    ...
  },
  ...
]
```


### Advanced Details

To use this program you have to install the required depencies listed in the `mix.exs` file, specifically in the `deps` function. To install the dependencies just run `$ mix deps.get` in a terminal prompt and it will download all the files into a `deps` folder at the root level. Elixir Mix projects are in some way like Node projects (If you are familiar with Node), where basically all of yout project's dependencies live inside the project's directory. 

Once you have installed all of the dependencies, execute the Mix task `$ mix escript.build` to compile the source code and all of its dependencies into bytecode that can be run and interpreted by the Erlang VM. It basically creates a command line executable that you can use to run the program in UNIX based platforms that have Erlang installed. 

The purpose of this program is to scrape concurrently (separate processes) the data from some Udemy courses pages and retrieve the relevant data as a JSON document (see sample output below). This version proved to be upto ***6x*** times faster than the non concurrent version of this program and upto ***10x*** faster than a [Ruby](https://github.com/Angarsk8/udemy_courses_scraping) version of this program, in a couple of tests that I did in my computer. I haven't done any proper benchmark to test that better, but I will include one in the future. 

To execute the program you have to run the following command:

```
$ ./courses_scraper <path_to_the_file_with_courses_paths>
```

Where the `<path_to_the_file_with_courses_paths>` is a file containing the paths associated with the Udemy courses to be scraped. The file must have the following shape in order to work.

```
 curso-completo-desarrollador-ios-15-apps android-basico
 curso-de-desarrollo-de-apps-para-ios-9 desarrollo-ios-con-swift 
 aprende-wordpress-sin-conocimientos-previos creando-paginas-web-con-html5-css3-y-bootstrap-3 programacion-para-emprendedores ...
```

That means, the file must contains the paths that yield to their respective Udemy websites separated by one or more spaces. 