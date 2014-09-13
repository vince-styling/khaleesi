Khaleesi is a blog-aware or documentation-aware static site generator write in Ruby, looks like a text transformation engine to transforming your plain text into static websites. Supports markdown parser, series of decorators wrapping, code syntax highlighting, simple page script programming, page including, dataset traversing etc.

`Khaleesi` was designed as an elegant personal technology blog generate tool, used [Redcarpet](https://github.com/vmg/redcarpet) as markdown parser, same as [Jekyll](http://jekyllrb.com/docs/templates/#code-snippet-highlighting), also use [Rouge](https://github.com/jneen/rouge) and [Pygments](https://github.com/tmm1/pygments.rb) as syntax highlighter, above themes are export from Rouge that give you a few options you probably needed in future.




# Installation

Getting Khaleesi installed and ready-to-go should only take a few minutes, it's distributed using the RubyGems package manager, this means you will need both the Ruby language runtime installed and RubyGems to begin using Khaleesi.

## Requirements

Installing Khaleesi is easy and straightforward, but there are a few requirements you'll need to make sure your system has before you start.

- Ruby (>= 2.1.2)
- RubyGems (>= 2.2.2)
- Linux, Unix, or Mac OS X(seemed not support Windows)

Mac OS X comes prepackaged with both Ruby and RubyGems after you installed Command Line Tools for Xcode. However, both Khaleesi requires might be old, below is what versions i'm developing on :

```bash
# => make sure the ruby version >= 2.1.2
~ $ /usr/bin/ruby --version

# => make sure the RubyGems version >= 2.2.2
~ $ /usr/bin/gem --version
```

## Install with RubyGems

Once you have Ruby and RubyGems up, you are ready to install Khaleesi. At the terminal prompt, you can simply run the following command to install :

```bash
[sudo] gem install khaleesi
```

All of Khaleesi’s gem dependencies are automatically installed by the above command, so you won't have to worry about them at all.

The installation process will add one new command to your environment, with 5+ useful features :

- khaleesi produce
- khaleesi construction
- khaleesi createpost
- khaleesi generate
- khaleesi build

The uses of each of these commands will be covered below.

Now that you've got everything installed, let's get to work!




# Quick-start Guide

The most straightforward to have a boilerplate Khaleesi site up and running :

```bash
~ $ khaleesi construction mysite
~ $ cd mysite
~ $ ./mysite generate
~ $ ./mysite serve
# => Now browse to http://localhost:9090
```

The `khaleesi construction` command will create a site which named for you in argument, and build it skeleton in that folder, then we serve that folder via HTTP so we can visit all pages of that site in browser.




# The "khaleesi" command

As mentioned earlier, the gem makes a `khaleesi` executable available to you in Terminal. You can use this command in a number of ways :

```bash
~ $ khaleesi produce
# => produce html code for specify markdown file

~ $ khaleesi construction
# => create a site directory with whole structure at present working directory(pwd)

~ $ khaleesi createpost
# => create a new page in pwd with an unique identifier which
#    composed by 20 characters like "b36446316f29e2b97a7d"

~ $ khaleesi generate
# => generate whole site for specify directory

~ $ khaleesi build
# => build whole site for specify directory
```

Just point `khaleesi help [command]` command in Terminal to see more details.




# The Site Skeleton

The `khaleesi construction` command creates a basic web development skeleton for you, a standard hierarchy of folders and files that you can use in all of your sites. Throughout that process you can tweak how you want the site URLs to look, what data gets displayed in the layout, assembly multiple pages into one, and more. This is all done through editing files, and the static web site is the final product.

A basic Khaleesi site usually looks something like this :

```bash
~/mysite $ tree
.
├── _decorators
│   ├── basic.html
│   └── post.html
├── _pages
│   ├── index.html
│   └── posts
│       ├── 2013
│       │   └── netroid-introduction.md
│       └── 2014
│           └── khaleesi-introduction.md
├── _raw
│   ├── css
│   │   └── site.css
│   └── images
│       └── bg.jpg
└── mysite

8 directories, 8 files
```

An overview of what each of these does :

| File / Directory | Description |
| :-------------: | :------------- |
| `_decorators` | These are the templates that wrap pages. All decorator files can be mixed and reuse, they chosen on file-by-file inject content since page indicating the root decorator. |
| `_pages` | Well-formatted site data folder where all pages you want to display should be placed here. This means that you can publish and maintain a site simply by managing a folder of text-files on your computer. The Khaleesi engine will load all files(ends with `.md` or `.html` in general) and generating as website in this directory. |
| `posts` | Your dynamic content, the permalinks can be customized for each post, will explain further about how to do it. |
| `index.html` | Most came as the first page of site, it will be transformed by Khaleesi. The same will happen for any `.html`, `.md` file in your site's root directory(calls `_pages`, described above). |
| `_raw` | Every other directory and file except for those listed above should be placed here. Such as css files, images folders etc. All files in this folder will be copied verbatim to the generated site. |

Below are several of sites already using Khaleesi, if you're curious to see how they're laid out.

- [My personal blog](http://vincestyling.com/)
- [Netroid : a http framework for android](http://netroid.cn/)

Of course this documentation site you are visiting on also builded via Khaleesi.




# Configuration

The Khaleesi command's `generate` and `build` goals are used to build your site, both of them were almost equally, excepted the handle policy of `_raw` directory, they accepted many configure arguments to concoct your site.

```bash
~ $ khaleesi help generate
usage: khaleesi generate [options...]

--src-dir
# => required, specify a source directory path(must be absolutely),
#    khaleesi shall generating via this site source.

--dest-dir
# => required, specify a destination directory path(must be absolutely),
#    all generated file will put there.

--line-numbers
# => (true|false) enable or disable output source code line numbers.
#    the default value is "false", which means no line numbers at all.

--css-class
# => specify source code syntax highlight's css class, default is 'highlight'.

--time-pattern
# => specify which time pattern would be used, If not provided,
#    khaleesi will use '%a %e %b %H:%M %Y' as default.
#    see http://www.ruby-doc.org/core-2.1.2/Time.html#strftime-method for pattern details.

--date-pattern
# => specify which date pattern would be used, If not provided, khaleesi will use '%F' as default.

--diff-plus
# => (true|false) if given the value is 'true', khaleesi will only generate local repository(git)
#    changed but has not yet been versionadded's pages.
#    If the whole site was too many pages or some pages had time-consuming operation in building,
#    it would be expensively when you want just focusing on those pages you frequently changing on,
#    e.g. you are writing a new post, you probably just care what looks would post be at all,
#    so this setting let's avoid to generating extra pages which never changes.

--highlighter
# => (pygments|rouge) tells Khaleesi what syntax highlighter you prefer to use,
#    every value except 'pygments' means the same as 'rouge'.

--toc-selection
# => specify which headers will generate an "Table of Contents" id,
#    default is empty, that means disable TOC generation.
#    Enable values including "h1,h2,h3,h4,h5,h6", use comma as separator
#    to tell Khaleesi which html headers you want to have ids.
#    If enable to generate ids, Khaleesi will deal with header's text finally produce an id
#    that only contain [lowercase-alpha, digit, dashes, underscores] characters.
#    According this rule, Khaleesi may hunting down your texts when they don't write correctly.
#    That shall cause the generated text become meaningless and even very easy to being duplicate.
#    In case your texts aren't write in a good form, you still have a setting to force Khaleesi
#    to generate an unique ids instead that uncomfortable generated texts.
#    Just append "[unique]" identifier at the end, e.g. "h1,h2[unique]", Khaleesi will generating
#    ids like these : "header-1", "header-2", "header-3", "header-4".
```

The list above show you all the available settings for Khaleesi, these various options can be specified from the command line executable, but it's easier to have a shell script to carry them so you don't have to remember them. You might notice i did it in the boilerplate khaleesi site, that shell file calls `mysite` in that time.

```bash
#!/bin/bash

src_dir=~/dev/khaleesi/demonstration
dest_dir=~/dev/khaleesi/demonstration/site
line_numbers="true"
css_class="highlight"
time_pattern="%Y-%m-%d %H:%M"
date_pattern="%F"
highlighter=""
# highlighter="pygments"
toc_selection="h1,h2"
# toc_selection="h1,h2[unique]"

if [[ "$1" == "generate" ]]; then
  diff=$([ "$2" == 'diff' ] && echo "true" || echo "false")
  khaleesi generate --src-dir "$src_dir" --dest-dir "$dest_dir" --line-numbers $line_numbers \
    --css-class $css_class --time-pattern "$time_pattern" --date-pattern "$date_pattern" \
    --diff-plus "$diff" --highlighter "$highlighter" --toc-selection "$toc_selection"

elif [[ "$1" == "build" ]]; then
  temperary_dest_dir=~/tmp_site
  mkdir $temperary_dest_dir

  cd $src_dir

  git checkout master

  khaleesi build --src-dir "$src_dir" --dest-dir "$temperary_dest_dir" --line-numbers $line_numbers \
    --css-class $css_class --time-pattern "$time_pattern" --date-pattern "$date_pattern" \
    --highlighter "$highlighter" --toc-selection "$toc_selection"

  git checkout gh-pages

  rsync -acv $temperary_dest_dir/ .
  rm -fr $temperary_dest_dir

elif [[ "$1" == "serve" ]]; then
  #nohup ruby -run -e httpd $dest_dir -p 9090 &
  ruby -run -e httpd $dest_dir -p 9090

fi
```

You may either wondering about the `build` sub-command or what's `gh-pages` branch. That command is going to build our site then commit to [Github Pages](https://pages.github.com/), and Github Pages was the best choice we can find to hosting our site upon Internet. With it, the only one thing you need to do just commit your static site files into a branch calls `gh-pages`, then simply execute `git push`
to github repository, github would serve your site as soon as possible. This can save our huge time and put rent VPS and many other troubles behind us.

In addition for Khaleesi command's `generate` and `build`, the `serve` sub-command can serving your destination directory over Http, gave us a simplest way to check what do we have in browser.

## Choice between Rouge and Pygments

The `--highlighter` option in particular, is a setting for choose which syntax highlighter you prefer to use. Khaleesi has built in support for syntax highlighting of [over 100 languages](http://pygments.org/languages/) thanks to [Pygments](http://pygments.org/). To use Pygments, you must have Python installed on your system and set **--highlighter** to pygments.

```bash
~ $ khaleesi generate|build --highlighter pygments
```

Alternatively, you can use Rouge to highlighting your code snippets. It doesn't support as many languages as Pygments does, but it should fit in most cases and it's written in pure Ruby, that means you don't need Python on your system.

I've compare them, i found the dealing time elapsed often within 10 milliseconds per page even if that page was complicated once you point Rouge as syntax highlighter. Following process log with time statistics would precisely to understand this.

```bash
# => process by Pygments
~ $ demonstration generate
Done (219 milliseconds) => '~/demonstration/site/index.html' bytes[13103].
Done (150 milliseconds) => '~/demonstration/site/themes/base16.html' bytes[13339].
Done (14 milliseconds) => '~/demonstration/site/themes/base16_dark.html' bytes[13319].
Done (13 milliseconds) => '~/demonstration/site/themes/base16_solarized.html' bytes[14012].
Done (11 milliseconds) => '~/demonstration/site/themes/base16_solarized_dark.html' bytes[13996].
Done (15 milliseconds) => '~/demonstration/site/themes/github.html' bytes[21702].
Done (14 milliseconds) => '~/demonstration/site/themes/monokai.html' bytes[21366].
Done (15 milliseconds) => '~/demonstration/site/themes/monokai_sublime.html' bytes[21718].
Done (13 milliseconds) => '~/demonstration/site/themes/thankful_eyes.html' bytes[19258].
Generator time elapsed : 469 milliseconds.

# => process by Rouge
~ $ demonstration generate
Done (14 milliseconds) => '~/demonstration/site/index.html' bytes[9330].
Done (11 milliseconds) => '~/demonstration/site/themes/base16.html' bytes[13077].
Done (7 milliseconds) => '~/demonstration/site/themes/base16_dark.html' bytes[13055].
Done (7 milliseconds) => '~/demonstration/site/themes/base16_solarized.html' bytes[13751].
Done (7 milliseconds) => '~/demonstration/site/themes/base16_solarized_dark.html' bytes[13732].
Done (10 milliseconds) => '~/demonstration/site/themes/github.html' bytes[21488].
Done (10 milliseconds) => '~/demonstration/site/themes/monokai.html' bytes[21147].
Done (9 milliseconds) => '~/demonstration/site/themes/monokai_sublime.html' bytes[21489].
Done (8 milliseconds) => '~/demonstration/site/themes/thankful_eyes.html' bytes[19018].
Generator time elapsed : 110 milliseconds.
```

As you can see, Rouge's performance was impressive, i'll spare you the details of why she does. In my opinion, i'd use both, Rouge would be more suitable when i'm working locally, because i much care the time-consuming in this situation. When i'm ready to publish my site, bit of generate time increase is tolerable. Indeed, if you paste some languages that Rouge didn't support them, you might be only use Pygments. But it's okay, Pygments would never hurt, it just need a relatively long time to preparing the Python child process. Once it get startup, all next dealing performance would be obviously improve as quickly as Rouge does.

## How to enable syntax highlighting in markdown?

Blocks of code are either fenced by lines with three back-ticks ```, or are indented with four spaces. I recommand only using the fenced code blocks, because they're easier and only they support syntax highlighting. To render a code block with syntax highlighting, surround your code as follows in markdown file :

    ```javascript
    var s = "JavaScript syntax highlighting";
    alert(s);
    ```
     
    ```python
    s = "Python syntax highlighting"
    print s
    ```

The argument to the highlight tag ("javascript" and "python" in the example above) is the language identifier. To find the appropriate identifier to use for the language you want to highlight, look for the "short name" on the [Pygments's Lexers page](http://pygments.org/docs/lexers/) or the [Rouge wiki](https://github.com/jneen/rouge/wiki/List-of-supported-languages-and-lexers).


### Stylesheets for syntax highlighting

In order for the highlighting to show up, you'll need to include a highlighting stylesheet. Around this demonstration site, you'll able to get 8 stylesheets, just choose one you perfer and download corresponding css file. Our stylesheets were fully compatible with Pygments and Rouge, either syntax highlighter would output identical html structure. That means you can switch both syntax highlighters effortlessly, view this page's source to see what kind of highlight block you'll get if interested.



# Development

As explained on the directory skeleton preceding, the `_pages` folder is where your site pages will live. These pages can be either Markdown(ends with `*.md`) or Html(ends with `*.html`) formatted text files. These formats each have their own way of making up different types of content within a page. Markdown usually used to writing the main content of page like blog post. Html could be better at writing page logical like **foreach** or **including**. As long as they stay in right suffix, they will be converted from their source format into an HTML page that is part of your static site.


## Creating Pages

To create a new page, all you need to do is create a new file inside the `_pages` directory, put any sub-directory you wanted. How you naming files is important, Khaleesi only capable of text-files, requires files to be named ends with `*.html|md`.

All page files can declare variables section and content section, separate them with 6+ `‡`(END OF SELECTED AREA), a common page structure would being this :

```
title: Demonstration of Khaleesi
decorator: basic
slug: index.html
‡‡‡‡‡‡‡‡‡‡ 
Here is page content.
```

About the variables section, it's syntax just like a json object, one key-value pair define one variable in single line. About the content section, it's syntax depends on what format of page you are using, if `*.html`, it should write as html content, and if `.md`, it's Markdown syntax supported.

You can put any files that supports by Khaleesi inside the `_pages` directory, but not each file can be a standalone web page. What makes a file become web page? A valid web page must declare **title** and **decorator** variables, title was the basic part of a common html page, and Khaleesi demand every page must inject into a decorator file at least.


## Understanding Pages

You can imagine a page just like a database table row, the table name is the directory name where they sit in. e.g. you have a directory named `themes`, and files content obey the page structure pattern, the hierarchical look like this :

```
demonstration/_pages/themes
├── base16.md
│   └──│ title: theme of base16
│      │ decorator: theme_dor
│      │ slug: base16.html
│      │ ‡‡‡‡‡‡‡‡‡‡
│      │ Here is base16 theme's content.
│
├── base16_dark.md
│   └──│ title: theme of base16_dark
│      │ decorator: theme_dor
│      │ slug: base16_dark.html
│      │ ‡‡‡‡‡‡‡‡‡‡
│      │ Here is base16_dark theme's content.
│
├── github.md
│   └──│ title: theme of github
│      │ decorator: theme_dor
│      │ slug: github.html
│      │ ‡‡‡‡‡‡‡‡‡‡
│      │ Here is github theme's content.
│
└── monokai_sublime.md
    └──│ title: theme of monokai_sublime
       │ decorator: theme_dor
       │ slug: monokai_sublime.html
       │ ‡‡‡‡‡‡‡‡‡‡
       │ Here is monokai_sublime theme's content.
```

The directory name : `themes` equivalent the table name, every file representing one row, so the dataset of above hierarchy can organize as this table structure :

| title | decorator | slug | content |
| ---- | ---- | ---- | ---- |
| theme of base16 | theme_dor | base16.html | Here is base16 theme's content. |
| theme of base16_dark | theme_dor | base16_dark.html | Here is base16_dark theme's content. |
| theme of github | theme_dor | github.html | Here is github theme's content. |
| theme of monokai_sublime | theme_dor | monokai_sublime.html | Here is monokai_sublime theme's content. |


## Foreach Loop

Khaleesi use `foreach` logical to loop a directory(table), the **foreach** code snippet must write in a html page :

```html
title: index
decorator: basic
‡‡‡‡‡‡‡‡‡‡ 
<div class="themes_cont">
    <ul class="themes">
        #foreach ($theme : $themes)
            <li title="${theme:title}">
                <a href="${theme:link}">
                    <span>${theme:title}</span>
                    <span>${theme:createdate}</span>
                </a>
                <p>${theme:content}</p>
            </li>
        #end
    </ul>
</div>
```

The declare of **$themes** actually represent a folder name, in this case, we have a folder inside **_pages** named `themes`, just as `$studios` would point to `_pages/studios` folder. This loop will take all files inside that directory and it's sub-directories recursively, gather all valid files as an **Array**, then evaluating the loop's repeatable segment one by one finally output them as parsed blocks. Follows above illustrative hierarchy, the final evaluate result would be this :

```html
<div class="themes_cont">
    <ul class="themes">
        <li title="theme of base16">
            <a href="/themes/base16.html">
                <span>theme of base16</span>
                <span>2014-09-01</span>
            </a>
            <p>Here is base16 theme's content.</p>
        </li>
        <li title="theme of base16_dark">
            <a href="/themes/base16_dark.html">
                <span>theme of base16_dark</span>
                <span>2014-09-01</span>
            </a>
            <p>Here is base16_dark theme's content.</p>
        </li>
        <li title="theme of github">
            <a href="/themes/github.html">
                <span>theme of github</span>
                <span>2014-09-01</span>
            </a>
            <p>Here is github theme's content.</p>
        </li>
        <li title="theme of monokai_sublime">
            <a href="/themes/monokai_sublime.html">
                <span>theme of monokai_sublime</span>
                <span>2014-09-01</span>
            </a>
            <p>Here is monokai_sublime theme's content.</p>
        </li>
    </ul>
</div>
```

The `foreach` loop's syntax was inherited from **Apache Velocity**, design for traverses all files of directory which inside the **_pages** directory. In above case, foreach logical causes the **$themes** page list to be looped over for all of the theme. Each time through the loop, the page from $themes is placed into the **$theme** scope, and the segment who planning to repeat would be evaluate and output as parsed html.


### Sub-directory loop

Looping sub-directory was acceptable, if you organize your pages in sub-directory, you need to include that direcoty's relative path in the **foreach** snippet. For instance, you placed lots of pages into `_pages/studio/cameras/` folder, the way you want to display all **cameras** is this :

```
#foreach ($camera : $studio/cameras)
    ...
#end
```

### Page sorting

After we collect all valid files of directory as an **Array**, we'll sort them in ascending order before we evaluating them. Khaleesi support two mode page sorting :

**By sequence declaration** : every page can declare a variable named `sequence` and specify an integer value. If this variable present, we'll compare their value priority.

```
such as this hierarchy loop :

demonstration/_pages/themes
├── base16.md
│   └──│ title: theme of base16
│      │ sequence: 2
│
├── base16_dark.md
│   └──│ title: theme of base16_dark
│      │ sequence: 3
│
├── github.md
│   └──│ title: theme of github
│      │ sequence: 1
│
└── monokai_sublime.md
    └──│ title: theme of monokai_sublime
       │ sequence: 4

will produce such as this list :

theme of github
theme of base16
theme of base16_dark
theme of monokai_sublime
```

**By create time** : Khaleesi will execute a command to take the first versioned time of page in Git repository as create time, then compare their times. If Git didn't installed or that page haven't versioned, we'll take current time as replacement.

### Order-by-limit

Whichever order by **sequence** or **create time**, the collection was sort ascending. Khaleesi allows you to have a descending order list specified by declaring `foreach` logical :

```
#foreach ($camera : $studio/cameras desc|asc)
    ...
#end
```

Also allows to limit how many items would be loop :

```
#foreach ($camera : $studio/cameras 5)
    ...
#end
```

two conditions at once :

```
#foreach ($camera : $studio/cameras desc 5)
    ...
#end
```

Just like the SQL's way to manipulate a result list, in this example, we turn the page list order by descending and limit 5 items to be looping. This customization could be advantage for display a list like "Recent posts".



## Chain logical

Every web page usually been an item in an **ordered list**, as long as they stay with their siblings, they able to have previous or next object. Khaleesi allows you to take those next to objects for current page. e.g. in this demonstration site, you'll find 8 theme's detail pages, each page has previous theme or next theme.

```html
#if chain:prev($theme)
    <div class="prev">Prev Theme : <a href="${theme:link}">${theme:title}</a></div>
#end

#if chain:next($theme)
    <div class="next">Next Theme : <a href="${theme:link}">${theme:title}</a></div>
#end
```

Apply this logical snippet in each theme's detail page, Khaleesi will take previous and next theme of theme which generating on, evaluate logical's body **if** theme presenting.

With this approach, you can navigate users further to learn your site. That may not suit everyone, but for people who like to build a documentation site like [Jekyll](http://jekyllrb.com/docs/home/) it's simple and works.



## Variables

A legal variable must obey this pattern `${[scope]:[name]}`, whether variable's **scope** or **name**, they remain case sensitive and only accepted non-blank characters. e.g. **${variable:Name}** would be differential treatment with **${variable:name}**, and writing as **${variable:safety car}** is invalid.

Khaleesi pre-defined a variety of data variable to simplify page programming, The following is a reference of them.

| name | scope | example | description |
| ---- | ----- | ----- | ----- |
| createtime | variable, customize_scope | ${variable:createtime}, ${theme:createtime} | Long pattern's create time of file, like '2014-08-22 16:45'. First versioned time fetch from **Git** repository, current time would be use if failure to taking that time. Pattern configurable by `--time-pattern`. |
| createdate | variable, customize_scope | ${variable:createdate}, ${theme:createdate} | Short pattern's create date like '2014-08-22', pattern configurable by `--date-pattern`. |
| modifytime | variable, customize_scope | ${variable:modifytime}, ${theme:modifytime} | Long pattern's modify time of file, last versioned time fetch from Git repository. |
| modifydate | variable, customize_scope | ${variable:createdate}, ${theme:createdate} | Short pattern's modify date relative to **modifytime**. |
| link | variable, customize_scope | ${variable:link}, ${theme:link} | Generate file's URL if that file is valid web page(a valid web page must declare **title** and **decorator** variable). The URL of file without the domain, but with a leading slash, e.g. `/posts/2014/my-post.html`. |
| content | decorator, customize_scope | ${decorator:content}, ${theme:content} | Inject the file's rendered content. Scoped to **decorator** means inject that file's content which declare this decorator now processing on as decorator. Scoped to **customize_scope** such as **theme** means process and output this scope pointing file's content, focus on **foreach** and **chain** logical for more details. |
| [page_name] | page | ${page:introduction} | A complex page usually have a few part of contents, Khaleesi allows we to assembly other files into a complete web page. We can specify the file name via variable name, for example is **introduction**. Khaleesi will locating a file named **introduction.html** or **introduction.md** in your site, then process its content to output by its formats. |

Throughout handling a page task, some pages might be load while a page need them to evaluating. All these relevant page's variable shall managing with a **Stack**, abandon instantly if that page was done. Khaleesi locating a variable in the Stack one by one until it find out. This principle enable us to find a variable from its parents if needed.



## The page link

How Khaleesi generate your web page's path depends on where you put that page files in. e.g. you have a page file that inside the `_pages/post/2014/` folder, you'll view that page in browser is **http://.../post/2014/PAGE-NAME**.

For the `PAGE-NAME`, Khaleesi supports a flexible way to resulting them. The directest approach of specify the page name you want to view is declare a variable named `slug`. Given a page path is `/_pages/posts/2014/khaleesi_info.html` :

```
title: Khaleesi's introduction
slug: mypost.html
decorator: basic
‡‡‡‡‡‡‡‡‡‡ 
here's page content.
```

Khaleesi will use `mypost.html` as this page's name, then the final url link would be **http://.../posts/2014/mypost.html**.

**Slug** variable was the preferred choice to naming a page, and if he **absent**, Khaleesi will take page's **title** variable as source to generating the page name but delete else of characters if not [alpha, digit, dash, underscore], so the final url link would be **http://.../posts/2014/khaleesis-introduction.html**.

Across in the Khaleesi process, the file name of page mostly not matter, excepted in this time. That dealing with **title** variable may hunt down the entire string causing it become empty while generating page name. e.g. your title is **一些一些情**, a chinese text won't be a wise file name or page name either. Make us hold nothing about page name in our hands, so the last factor we could rely on is the file name, thus the final url link would be **http://.../posts/2014/khaleesi_info.html**.



## The decorator files

As explained on the directory skeleton before, the `_decorators` folder is where you can store decorator files for Khaleesi to use when generating your site. All files inside that folder must ends with `.html`, and every page files on your site can apply decorator. A decorator file usually acting on common content, like headers and footers. They inject another decorator or page's content by writing `${decorator:content}` variable.

```html
<html>
    <head>
    	<title>${variable:title}</title>
    </head>
    <body>
    	<!-- Inject page content here. -->
    	${decorator:content}
    </body>
</html>
```

A decorator page can specify its own decorator, and so on. In fact, we usually have some of pages they share a same structure, e.g. blog post, we definitely wishes to create a template(here's decorator) to carry that common part for them so reduce codes.

```html
decorator: basic
‡‡‡‡‡‡‡‡‡‡ 
<div class="post_content">
	<h1 class="post_title">${variable:title}</h1>
    <div class="post_thumb">
        ${decorator:content}
    </div>
</div>
```

In this case, we have a small snippet for every blog post, each post content will inject into this decorator if they pointing him, then again decorating with a decorator named `basic.html` after current content evaluated.



## Generating page identifier

At some point, you may want to have an unique ID for every standalone web page. especially kind of blog post, people often assembling the [Disqus](https://disqus.com) to build a community of active readers and commenters. An identifier of these pages is important in this case. Of course you can let Disqus use page link as identifier, but it's never being flexible if you want to modify that link or you testing locally, so that's why an unique ID needed.

Khaleesi offer you a command to creating page with an unique identifier which composed by 20 characters, basically invoke a method named [SecureRandom.hex(10)](http://armoredcode.com/blog/create-random-keys-in-ruby-using-securerandom/). As Paolo Perego said in his post, **SecureRandom** can create a truly random key and it can be safe enough for our uniquify purpose.

```bash
~ $ khaleesi createpost mypost
~ $ cat mypost.md
title: <input post title>
decorator: <input page decorator>
identifier: 53cdcea1aec20ec4d8ef
‡‡‡‡‡‡‡‡‡‡‡‡‡‡ 
here is page content.
```



# Questions and Answers



## Why choose `‡` as separators?

The character of [‡(END OF SELECTED AREA)](http://www.fileformat.info/info/unicode/char/0087/index.htm) why i chose as separators since it's very rare in content writing. i originally used "---" as separators, but after i examined my codes, i realize that the continuous dashes may too familiar in contents, his existence would cause our regular expression work problematical. We can't recognize if the Regexp correct or wrong because that dashes probably presenting in page's content section. Thus the result of that Regexp can't be trust anymore, so i decide to use some odd enough characters instead of. Even if that characters present in content, i bet it's most unlikely to match my **6 or more counting** and **stand at independent line** rules, makes that characters safer than dashes.



## Why choose Ruby rather than Python?

Ruby and Python was the famous programming languages either. At the beginning, i do the technology selection depends on which syntax highlighter could be even more satisfying my desired. I found Rouge and Albino(replace by Pygments.rb soon) are brilliant at work with Redcarpet. Then i starting to compare Ruby and Python suitability, i discover Ruby provided more generous documentation than Python. Especially for String and Regexp, i really like its powerful regular expression, string functionality, code flow control statements. I believe Ruby is pick up easier than Python and more fit even more quickly and effectively to accomplish my blog generation purpose. Also another reason to motivate me use Ruby is **Jekyll** chose her too, so i've made my decision and prove the judgement was right.



## Why choose Khaleesi as project name?

"Khaleesi" is a Dothraki title referring to the wife of the khal in the Great Grass Sea, she could be very influential in the whole khalasar. This word inspired from my favorite books **A song of ice and fire** where the story coming from. According to the **Game of Thrones** TV, "Khaleesi" is pronounced "khal-EE-see". Play the role of her actor was quite beautiful and charming, she was my favorite character than the others, that's why we chose this name.



































