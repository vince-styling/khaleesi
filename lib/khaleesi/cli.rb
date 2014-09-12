require 'securerandom'

module Khaleesi
  class CLI
    def self.doc
      return enum_for(:doc) unless block_given?

      yield 'usage: khaleesi [command] [args...]'
      yield ''
      yield 'where <command> is one of:'
      yield %|	help\|h          #{Help.desc}|
      yield %|	version\|v       #{Version.desc}|
      yield %|	about           #{About.desc}|
      yield %|	produce\|p       #{Produce.desc}|
      yield %|	construction\|c  #{Construction.desc}|
      yield %|	createpost\|cp   #{CreatePost.desc}|
      yield %|	generate\|g      #{Generate.desc}|
      yield %|	build\|b         #{Build.desc}|
      yield ''
      yield 'See `khaleesi help <command>` for more info.'
    end

    def initialize(options={})
    end

    def self.parse(argv=ARGV)
      argv = normalize_syntax(argv)

      mode = argv.shift

      klass = class_from_arg(mode)
      klass.parse(argv)
    end

    def self.class_from_arg(arg)
      case arg
        when 'construction', 'c'
          Construction
        when 'createpost', 'cp'
          CreatePost
        when 'generate', 'g'
          Generate
        when 'version', 'v'
          Version
        when 'produce', 'p'
          Produce
        when 'build', 'b'
          Build
        when 'help', 'h'
          Help
        else
          About
      end
    end

    class Version < CLI
      def self.desc
        'print the khaleesi version number'
      end

      def self.parse(*)
        ; new;
      end

      def run
        puts "Khaleesi : #{Khaleesi.version}"
      end
    end

    class About < CLI
      def self.desc
        'print about khaleesi\'s information'
      end

      def self.parse(*)
        ; new;
      end

      def run
        puts Khaleesi.about
      end
    end

    class Produce < CLI
      def self.desc
        'produce html code for specify markdown file'
      end

      def self.doc
        return enum_for(:doc) unless block_given?

        yield 'usage: khaleesi produce <filename>'
        yield ''
        yield '<filename>  specify a file to read'
      end

      def self.parse(argv)
        opts = {:input_file => nil}

        until argv.empty?
          opts[:input_file] = argv.shift
        end

        puts 'unspecific markdown file' unless opts[:input_file]

        new(opts)
      end

      def input_stream
        @input_stream ||= FileReader.new(@input_file)
      end

      def input
        @input ||= input_stream.read
      end

      attr_reader :input_file

      def initialize(opts={})
        @input_file = opts[:input_file]
      end

      def run
        return unless @input_file
        print Generator.new.handle_markdown(input)
      end
    end

    class CreatePost < CLI
      def self.desc
        'create a new page in pwd with an unique identifier which composed by 20 characters like "b36446316f29e2b97a7d"'
      end

      def self.doc
        return enum_for(:doc) unless block_given?

        yield 'usage: khaleesi createpost <filename>'
        yield ''
        yield '<filename>  specify a page file name (exclude extension)'
      end

      def self.parse(argv)
        opts = {:page_name => nil}

        until argv.empty?
          opts[:page_name] = argv.shift
        end

        puts 'unspecific page name' unless opts[:page_name]

        new(opts)
      end

      attr_reader :page_name

      def initialize(opts={})
        @page_name = opts[:page_name]
      end

      def run
        return unless @page_name

        page_path = "#{Dir.pwd}/#{@page_name}.md"
        open(page_path, 'w') do |f|
          f.puts 'title: <input page title>'
          f.puts 'decorator: <input page decorator>'
          f.puts "identifier: #{SecureRandom.hex(10)}"
          f.puts '‡‡‡‡‡‡‡‡‡‡‡‡‡‡'
          f.puts 'here is page content.'
        end

        puts "A post page was created : #{page_path}."
      end
    end

    class Construction < CLI
      def self.desc
        'create a site directory with whole structure at present working directory(pwd)'
      end

      def self.doc
        return enum_for(:doc) unless block_given?

        yield 'usage: khaleesi construction <directory_name>'
        yield ''
        yield '<directory_name>  specify a directory name of site'
      end

      def self.parse(argv)
        opts = {:directory_name => nil}

        until argv.empty?
          opts[:directory_name] = argv.shift
        end

        puts 'unspecific directory name' unless opts[:directory_name]

        new(opts)
      end

      attr_reader :directory_name

      def initialize(opts={})
        @directory_name = opts[:directory_name]
      end

      def run
        return unless @directory_name

        root_dir = "#{Dir.pwd}/#{@directory_name}"

        gen_site = "#{root_dir}/gen_site"
        execute_script = create_file_p(root_dir, @directory_name, '')
        open(execute_script, 'w') do |f|
          f.puts '#!/bin/bash'
          f.puts ''
          f.puts "src_dir=#{root_dir}"
          f.puts "dest_dir=#{gen_site}"
          f.puts 'line_numbers="false"'
          f.puts 'css_class="highlight"'
          f.puts 'time_pattern="%Y-%m-%d %H:%M"'
          f.puts 'date_pattern="%F"'
          f.puts 'highlighter=""'
          f.puts '# highlighter="pygments"'
          f.puts 'toc_selection="h1,h2,h3"'
          f.puts '# toc_selection="h1,h2,h3[unique]"'
          f.puts ''

          f.puts 'if [[ "$1" == "generate" ]]; then'
          f.puts '  diff=$([ "$2" == \'diff\' ] && echo "true" || echo "false")'
          f.puts '  khaleesi generate --src-dir "$src_dir" --dest-dir "$dest_dir" --line-numbers $line_numbers \\'
          f.puts '    --css-class $css_class --time-pattern "$time_pattern" --date-pattern "$date_pattern" \\'
          f.puts '    --diff-plus "$diff" --highlighter "$highlighter" --toc-selection "$toc_selection"'
          f.puts ''
          f.puts 'elif [[ "$1" == "build" ]]; then'
          f.puts '  temperary_dest_dir=~/tmp_site'
          f.puts '  mkdir $temperary_dest_dir'
          f.puts ''
          f.puts '  cd $src_dir'
          f.puts ''
          f.puts '  git checkout master'
          f.puts ''
          f.puts '  khaleesi build --src-dir "$src_dir" --dest-dir "$dest_dir" --line-numbers $line_numbers \\'
          f.puts '    --css-class $css_class --time-pattern "$time_pattern" --date-pattern "$date_pattern" \\'
          f.puts '    --highlighter "$highlighter" --toc-selection "$toc_selection"'
          f.puts ''
          f.puts '  git checkout gh-pages'
          f.puts ''
          f.puts '  rsync -acv $temperary_dest_dir/ .'
          f.puts ''
          f.puts '  rm -fr $temperary_dest_dir'
          f.puts ''
          f.puts 'elif [[ "$1" == "serve" ]]; then'
          f.puts '  ruby -run -e httpd $dest_dir -p 9090'
          f.puts ''
          f.puts 'fi'
        end
        File.chmod(0755, execute_script)
        FileUtils.mkdir_p(gen_site)

        css_dir = "#{root_dir}/_raw/css"
        css_file = create_file_p(css_dir, 'site', 'css')
        open(css_file, 'w') do |f|
          f.puts '* {margin:0; padding:0;}'
          f.puts 'body {margin:40px auto; width:940px; line-height:1.8em;}'

          f.puts 'a {color:#149ad4; text-decoration:none;}'
          f.puts 'a:hover {text-decoration:underline;}'

          f.puts '.header { font-size: 18px; padding-bottom: 10px; margin-bottom: 10px; border-bottom: 1px solid #ddd; box-shadow: 0 1px 0 rgba(255,255,255,0.5);}'
          f.puts '.content { font-size: 20px; padding-bottom: 10px; }'

          f.puts '.content .primary .post_list {'
          f.puts '  list-style-type: none;'
          f.puts '}'

          f.puts '.content .primary .post_list li {'
          f.puts '  border: 1px solid #ddd;'
          f.puts '  margin-bottom: 10px;'
          f.puts '  padding: 10px;'
          f.puts '}'

          f.puts '.content .primary .post_list li p {'
          f.puts '  color: #5c5855;'
          f.puts '  font-size: 16px;'
          f.puts '}'

          f.puts '.content .primary .post_list li span {'
          f.puts '  color: #60E;'
          f.puts '  font-size: 12px;'
          f.puts '}'

          f.puts '.content .post_title {'
          f.puts '  margin: 10px 0;'
          f.puts '  font-size: 32px;'
          f.puts '  text-align: center;'
          f.puts '}'

          f.puts '.footer {'
          f.puts '  width: 100%;'
          f.puts '  margin: 0 auto;'
          f.puts '  border-top: 2px solid #d5d5d5;'
          f.puts '  font-size: 13px;'
          f.puts '  color: #666;'
          f.puts '  padding-top: 10px;'
          f.puts '  padding-bottom: 60px;'
          f.puts '  line-height: 1.8em;'
          f.puts '}'

          f.puts '.footer .left {'
          f.puts '  float: left;'
          f.puts '}'

          f.puts '.footer .right {'
          f.puts '  float: right;'
          f.puts '}'

          f.puts '.footer .right div {'
          f.puts '  text-align: right;'
          f.puts '}'
        end

        FileUtils.mkdir_p("#{root_dir}/_raw/images")


        decorators_dir = "#{root_dir}/_decorators"
        decorator_file = create_file_p(decorators_dir, 'basic', 'html')
        open(decorator_file, 'w') do |f|
          f.puts '<!DOCTYPE html>'
          f.puts '<html xmlns="http://www.w3.org/1999/xhtml" dir="ltr" lang="en-US">'
          f.puts '    <head>'
          f.puts '        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
          f.puts '        <link rel="stylesheet" href="/css/site.css" type="text/css" media="screen">'
          f.puts '        <title>${variable:title}</title>'
          f.puts '    </head>'
          f.puts '    <body>'
          f.puts '        <div class="header">'
          f.puts '            A khaleesi demonstration site'
          f.puts '        </div>'
          f.puts '        <div class="content">'
          f.puts '            ${decorator:content}'
          f.puts '        </div>'
          f.puts '        <div class="footer">'
          f.puts '          <div class="left">'
          f.puts '            <div>Licensed under the <a href="http://choosealicense.com/licenses/mit/">MIT License</a></div>'
          f.puts '          </div>'
          f.puts '          <div class="right">'
          f.puts '            <div>A pure-ruby static site generator</div>'
          f.puts '            <div>Find <a href="https://github.com/vince-styling/khaleesi">khaleesi</a> in github</div>'
          f.puts '          </div>'
          f.puts '        </div>'
          f.puts '    </body>'
          f.puts '</html>'
        end

        decorator_file = create_file_p(decorators_dir, 'post', 'html')
        open(decorator_file, 'w') do |f|
          f.puts 'decorator: basic'
          f.puts '‡‡‡‡‡‡‡‡‡‡‡‡‡‡'
          f.puts '<h1 class="post_title">${variable:title}</h1>'
          f.puts '<div class="post-thumb">'
          f.puts '    ${decorator:content}'
          f.puts '</div>'
        end


        pages_dir = "#{root_dir}/_pages"
        index_file = create_file_p(pages_dir, 'index', 'html')
        open(index_file, 'w') do |f|
          f.puts 'title: Khaleesi Index'
          f.puts 'decorator: basic'
          f.puts 'slug: index.html'
          f.puts '‡‡‡‡‡‡‡‡‡‡‡‡‡‡'
          f.puts '<div class="primary">'
          f.puts '    <ul class="post_list">'
          f.puts '        #foreach ($post : $posts)'
          f.puts '            <li title="${post:title}">'
          f.puts '                <a href="${post:link}">${post:title}</a>'
          f.puts '                <span>(${post:createtime})</span>'
          f.puts '                <p>${post:description}</p>'
          f.puts '            </li>'
          f.puts '        #end'
          f.puts '    </ul>'
          f.puts '</div>'
        end

        pages_dir << '/posts'
        post_file = create_file_p("#{pages_dir}/2014", 'khaleesi-introduction', 'md')
        open(post_file, 'w') do |f|
          f.puts 'title: khaleesi\'s introduction'
          f.puts 'decorator: post'
          f.puts 'description: Khaleesi is a static site generator that write by ruby.'
          f.puts '‡‡‡‡‡‡‡‡‡‡‡‡‡‡'
          f.puts ''
          f.puts 'Khaleesi is a static site generator that write by ruby, supported markdown parser, multiple decorators inheritance, simple page programming, page including, page dataset configurable etc.'
          f.puts ''
          f.puts 'please check [this](http://khaleesi.vincestyling.com/) for more details.'
        end

        post_file = create_file_p("#{pages_dir}/2013", 'netroid-introduction', 'md')
        open(post_file, 'w') do |f|
          f.puts 'title: netroid\'s introduction'
          f.puts 'decorator: post'
          f.puts 'description: Netroid is a Http Framework for Android that based on Volley.'
          f.puts '‡‡‡‡‡‡‡‡‡‡‡‡‡‡'
          f.puts ''
          f.puts 'Netroid library for Android'
          f.puts '---------------------------'
          f.puts ''
          f.puts 'Netroid is a http library for Android that based on Volley, That purpose is make your android development easier than before, provide fast, handly, useful way to do async http operation by background thread.'
          f.puts ''
          f.puts 'please check [this](https://github.com/vince-styling/Netroid) for more details.'
        end

        puts "A sample site of Khaleesi was built in #{root_dir}."
      end
    end

    class Generate < CLI
      def self.desc
        "#{cmd_name} whole site for specify directory"
      end

      def self.cmd_name
        self.name.to_s[/(.+)::(.+)/, 2].downcase
      end

      def self.doc
        return enum_for(:doc) unless block_given?

        yield "usage: khaleesi #{cmd_name} [options...]"
        yield ''
        yield '--src-dir        required, specify a source directory path(must be absolutely), khaleesi shall generating via this site source.'
        yield ''
        yield '--dest-dir       required, specify a destination directory path(must be absolutely), all generated file will put there.'
        yield ''
        yield '--line-numbers   (true|false) enable or disable output source code line numbers.'
        yield '                 the default value is "false", which means no line numbers at all.'
        yield ''
        yield '--css-class      specify source code syntax highlight\'s css class, default is \'highlight\'.'
        yield ''
        yield '--time-pattern   specify which time pattern would be used, If not provided, khaleesi will use \'%a %e %b %H:%M %Y\' as default,'
        yield '                 see http://www.ruby-doc.org/core-2.1.2/Time.html#strftime-method for pattern details.'
        yield ''
        yield '--date-pattern   specify which date pattern would be used, If not provided, khaleesi will use \'%F\' as default,'
        yield '                 see http://www.ruby-doc.org/core-2.1.2/Time.html#strftime-method for pattern details.'
        yield ''
        yield '--diff-plus      (true|false) if given the value is \'true\', khaleesi will only generate local repository(git) changed'
        yield '                 but has not yet been versionadded\'s pages. If the whole site was too many pages or some pages had time-consuming'
        yield '                 operation in building, it would be expensively when you want just focusing on those pages you frequently changing on,'
        yield '                 e.g you are writing a new post, you probably just care what looks would post be at all,'
        yield '                 so this setting let\'s avoid to generating extra pages which never changes.'
        yield ''
        yield '--highlighter    (pygments|rouge) tells khaleesi what syntax highlighter you prefer to use,'
        yield '                 every value except \'pygments\' means the same as \'rouge\'.'
        yield ''
        yield '--toc-selection  specify which headers will generate an "Table of Contents" id,'
        yield '                 default is empty, that means disable TOC generation.'
        yield '                 Enable values including "h1,h2,h3,h4,h5,h6", use comma as separator'
        yield '                 to tell Khaleesi which html headers you want to have ids.'
        yield '                 If enable to generate ids, Khaleesi will deal with header\'s text finally produce an id'
        yield '                 that only contain [lowercase-alpha, digit, dashes, underscores] characters.'
        yield '                 According this rule, Khaleesi may hunting down your texts when they don\'t write correctly.'
        yield '                 That shall cause the generated text become meaningless and even very easy to being duplicate.'
        yield '                 In case your texts aren\'t write in a good form, you still have a setting to force Khaleesi'
        yield '                 to generate an unique ids instead that uncomfortable generated texts.'
        yield '                 Just append "[unique]" identifier at the end, e.g "h1,h2[unique]", Khaleesi will generating'
        yield '                 ids like these : "header-1", "header-2", "header-3", "header-4".'
      end

      def self.parse(argv)
        opts = {}
        argv = normalize_syntax(argv)
        until argv.empty?
          arg = argv.shift
          case arg
            when 'src-dir'
              opts[:src_dir] = argv.shift.dup
            when 'dest-dir'
              opts[:dest_dir] = argv.shift.dup
            when 'line-numbers'
              opts[:line_numbers] = argv.shift.dup
            when 'css-class'
              opts[:css_class] = argv.shift.dup
            when 'time-pattern'
              opts[:time_pattern] = argv.shift.dup
            when 'date-pattern'
              opts[:date_pattern] = argv.shift.dup
            when 'diff-plus'
              opts[:diff_plus] = argv.shift.dup
            when 'highlighter'
              opts[:highlighter] = argv.shift.dup
            when 'toc-selection'
              opts[:toc_selection] = argv.shift.dup
          end
        end

        new(opts)
      end

      def initialize(opts={})
        @opts = opts
      end

      def run
        details = " Please point \"khaleesi help #{self.class.to_s[/(.+)::(.+)/, 2].downcase}\" in terminal for more details."

        dest_dir = @opts[:dest_dir]
        src_dir = @opts[:src_dir]

        unless src_dir and File.directory?(src_dir) and File.readable?(src_dir)
          abort "Source directory : #{src_dir} invalid." << details
        end

        unless dest_dir and File.directory?(dest_dir) and File.writable?(dest_dir)
          abort "Destination directory : #{dest_dir} invalid." << details
        end

        site_dir = src_dir + '/_decorators'
        unless File.directory?(site_dir)
          abort "Source directory : #{src_dir} haven't _decorators folder."
        end

        site_dir = src_dir + '/_pages'
        unless File.directory?(site_dir)
          abort "Source directory : #{src_dir} haven't _pages folder."
        end

        site_dir = src_dir + '/_raw'
        unless File.directory?(site_dir)
          abort "Source directory : #{src_dir} haven't _raw folder."
        end

        Generator.new(@opts).generate
        handle_raw_files(site_dir)
      end

      def handle_raw_files(raw_dir)
        # make symbolic links of "_raw" directory
        Dir.chdir(@opts[:dest_dir]) do
          %x[ln -sf #{raw_dir << '/*'} .]
        end
        # FileUtils.ln_s site_dir << '/*', @dest_dir, :verbose => true
      end
    end

    class Build < Generate
      def handle_raw_files(raw_dir)
        FileUtils.cp_r raw_dir << '/.', @opts[:dest_dir], :verbose => false
      end
    end

    class Help < CLI
      def self.desc
        'print help info'
      end

      def self.doc
        return enum_for(:doc) unless block_given?

        yield 'usage: khaleesi help <command>'
        yield ''
        yield 'print help info for <command>.'
      end

      def self.parse(argv)
        opts = {:mode => CLI}
        until argv.empty?
          arg = argv.shift
          klass = class_from_arg(arg)
          if klass
            opts[:mode] = klass
            next
          end
        end
        new(opts)
      end

      def initialize(opts={})
        @mode = opts[:mode]
      end

      def run
        @mode.doc.each(&method(:puts))
      end
    end

    class FileReader
      attr_reader :input
      def initialize(input)
        @input = input
      end

      def file
        case input
          when '-'
            $stdin
          when String
            File.new(input)
          when ->(i){ i.respond_to? :read }
            input
        end
      end

      def read
        @read ||= begin
          file.read
        rescue => e
          $stderr.puts "unable to open #{input}: #{e.message}"
          exit 1
        ensure
          file.close
        end
      end
    end

    def create_file_p(dir, name, extension)
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      "#{dir}/#{name}" + (extension.empty? ? '' : ".#{extension}")
    end

    def self.normalize_syntax(argv)
      out = []
      argv.each do |arg|
        case arg
          when /^(-{,2})(\p{Graph}+)=(.*)$/
            out << $2 << $3
          when /^(-{,2})(\p{Graph}+)$/
            out << $2
          else
            out << arg
        end
      end

      out
    end
  end
end
