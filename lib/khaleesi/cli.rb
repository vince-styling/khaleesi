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
        when 'version', 'v'
          Version
        when 'produce', 'p'
          Produce
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
        print Khaleesi.handle_markdown(input)
      end
    end

    class CreatePost < CLI
      def self.desc
        'create a new post in pwd and generate a post identifier looks like "b36446316f29e2b97a7d"'
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

        open("#{Dir.pwd}/#{@page_name}.md", 'w') do |f|
          f.puts 'title: <input post title>'
          f.puts 'decorator: <input page decorator>'
          f.puts 'description: <input page description>'
          f.puts "identifier: #{SecureRandom.hex(10)}"
          f.puts '‡‡‡‡‡‡‡‡‡‡‡‡‡‡'
          f.puts ''
        end
      end
    end

    class Construction < CLI
      def self.desc
        'Create a site directory with whole structure at present working directory(pwd)'
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

        css_dir = "#{root_dir}/_raw/css"
        css_file = create_file_p(css_dir, 'site', 'css')
        open(css_file, 'w') do |f|
          f.puts 'body { border-top: 10px solid #f5f5f5; }'
          f.puts 'a { color: #d14; text-decoration: none; }'
          f.puts 'a:hover { text-decoration: underline; }'
          f.puts '.header { background-color: red; font-size: 20px; }'
          f.puts '.content { background-color: pink; font-size: 26px; }'
          f.puts '.footer { background-color: blue; font-size: 20px; }'
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
          f.puts '            This is Header'
          f.puts '        </div>'
          f.puts '        <div class="content">'
          f.puts '            ${decorator:content}'
          f.puts '        </div>'
          f.puts '        <div class="footer">'
          f.puts '            <hr/>'
          f.puts '            This is Footer'
          f.puts '        </div>'
          f.puts '    </body>'
          f.puts '</html>'
        end


        pages_dir = "#{root_dir}/_pages"
        index_file = create_file_p(pages_dir, 'index', 'html')
        open(index_file, 'w') do |f|
          f.puts 'title: Index Page'
          f.puts 'decorator: basic'
          f.puts '‡‡‡‡‡‡‡‡‡‡‡‡‡‡'
          f.puts '<div class="primary">'
          f.puts '    <ul class="post_list">'
          f.puts '        #foreach ($post : $posts)'
          f.puts '            <li title="${post:title}">'
          f.puts '                <a href="${post:link}">'
          f.puts '                    <span>${post:title}</span>'
          f.puts '                    <span>${post:createtime}</span>'
          f.puts '                    <span>${post:modifytime}</span>'
          f.puts '                    <p>${post:description}...</p>'
          f.puts '                </a>'
          f.puts '            </li>'
          f.puts '        #end'
          f.puts '    </ul>'
          f.puts '</div>'
        end

        pages_dir << '/posts'
        post_file = create_file_p("#{pages_dir}/2013", 'khaleesi-introduction', 'md')
        open(post_file, 'w') do |f|
          f.puts 'title: khaleesi\'s introduction'
          f.puts 'decorator: basic'
          f.puts 'description: Khaleesi is a static site generator that write by ruby.'
          f.puts '‡‡‡‡‡‡‡‡‡‡‡‡‡‡'
          f.puts ''
          f.puts 'Khaleesi is a static site generator that write by ruby, supported markdown parser, multiple decorators inheritance, simple page programming, page including, page dataset configurable etc.'
          f.puts ''
          f.puts 'please check [this](https://github.com/vince-styling/Khaleesi) for more details.'
        end

        post_file = create_file_p("#{pages_dir}/2014", 'netroid-introduction', 'md')
        open(post_file, 'w') do |f|
          f.puts 'title: netroid\'s introduction'
          f.puts 'decorator: basic'
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

      "#{dir}/#{name}.#{extension}"
    end

    def self.normalize_syntax(argv)
      out = []
      argv.each do |arg|
        case arg
          when /^(-{,2})(\w+)=(.*)$/
            out << $2 << $3
          when /^(-{,2})(\w+)$/
            out << $2
          else
            out << arg
        end
      end

      out
    end
  end
end
