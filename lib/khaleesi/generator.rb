module Khaleesi
  class Generator

    def initialize(src_dir, dest_dir, line_numbers, css_class, time_pattern, date_pattern, diff_plus)
      @src_dir = src_dir
      @dest_dir = dest_dir
      $line_numbers = line_numbers.eql?('true')
      $css_class = css_class
      @time_pattern = time_pattern
      @date_pattern = date_pattern
      @diff_plus = diff_plus.eql?('true')

      # puts "src_dir : #{@src_dir}"
      # puts "dest_dir : #{@dest_dir}"
      # puts "line_numbers : #{$line_numbers}"
      # puts "css_class : #{$css_class}"
      # puts "time_pattern : #{@time_pattern}"
      # puts "date_pattern : #{@date_pattern}"
      # puts "diff_plus : #{@diff_plus}"
    end

    def generate
      @decrt_regexp = produce_variable_regex('decorator')
      @title_regexp = produce_variable_regex('title')
      @var_regexp = /(\p{Word}+):(\p{Word}+)/
      @doc_regexp = /‡{6,}/

      @page_dir = "#{@src_dir}/_pages/"

      Dir.glob("#{@page_dir}/**/*") do |page_file|
        @page_file = File.expand_path(page_file)

        next if File.directory? @page_file
        next unless File.readable? @page_file
        next unless @page_file.end_with? '.md', '.html'

        if @diff_plus
          file_status = nil
          Dir.chdir(File.expand_path('..', page_file)) do
            file_status = %x[git status -s #{File.basename(page_file)}]
          end
          next unless file_status and file_status.strip.length > 2
        end

        extract_page_structure

        decorator = @variables ? @variables[@decrt_regexp, 3] : nil
        # page can't stand without decorator
        next unless decorator

        # isn't legal page if title missing
        title = @variables[@title_regexp, 3]
        next unless title

        parsed_content = parse_markdown_page(decorator) if page_file.end_with? '.md'
        parsed_content = parse_html_page(decorator) if page_file.end_with? '.html'
        # puts parsed_content

        page_path = File.expand_path(@dest_dir + get_link(@page_file, @variables))
        page_dir_path = File.dirname(page_path)
        unless File.directory?(page_dir_path)
          FileUtils.mkdir_p(page_dir_path)
        end

        bytes = IO.write(page_path, parsed_content)
        puts "Done => '#{page_path}' bytes[#{bytes}]."
      end
    end

    def parse_html_page(decorator)
      @content = parse_html_content(nil, @content, '')
      parse_decorator_file(decorator, @content)
    end

    def parse_markdown_page(decorator)
      @content = handle_markdown(@content)
      parse_decorator_file(decorator, @content)
    end

    def parse_decorator_file(decorator, content)
      parse_html_file("_decorators/#{decorator}.html", content)
    end

    def parse_html_file(sub_path, bore_content)
      html_content = IO.read("#{@src_dir}/#{sub_path}")

      if html_content.index(@doc_regexp)
        conary = html_content.split(@doc_regexp)
        page_s_variables = conary[0]
        html_content = conary[1]
      else
        page_s_variables = nil
      end

      parse_html_content(page_s_variables, html_content, bore_content)
    end

    def parse_html_content(page_s_variables, html_content, bore_content)
      parsed_text = handle_html_content(@page_file, page_s_variables, html_content, '')


      # http://www.ruby-doc.org/core-2.1.0/Regexp.html#class-Regexp-label-Repetition use '.+?' to disable greedy match.
      regexp = /(#foreach\p{Blank}?\(\$(\p{Alpha}+)\p{Blank}?:\p{Blank}?\$(\p{Alpha}+)\)(.+?)#end)\n/m
      while true
        foreach_snippet = parsed_text.match(regexp)
        break unless foreach_snippet

        foreach_snippet = handle_foreach_snippet(foreach_snippet)
        break unless foreach_snippet

        parsed_text.sub!(regexp, foreach_snippet)
      end


      parsed_text.sub!(/\$\{decorator:content}/, bore_content)


      # recurse parse the decorator
      decorator = page_s_variables ? page_s_variables[@decrt_regexp, 3] : nil
      decorator ? parse_decorator_file(decorator, parsed_text) : parsed_text
    end

    def handle_html_content(page_file, page_s_variables, html_content, added_scope)
      parsed_text = ''
      sub_script = ''

      html_content.each_char do |char|
        is_valid = sub_script.start_with?('${')
        case char
          when '$'
            sub_script.clear << char

          when '{'
            is_valid = sub_script.eql? '$'
            (is_valid ? sub_script : parsed_text) << char

          when ':'
            is_valid = is_valid && sub_script.length > 3
            (is_valid ? sub_script : parsed_text) << char

          when '}'
            is_valid = is_valid && sub_script.length > 4
            if is_valid
              sub_script << char

              form_scope = sub_script[@var_regexp, 1]
              form_value = sub_script[@var_regexp, 2]

              case form_scope
                when 'variable', added_scope

                  case form_value
                    when 'createtime'
                      create_time = Generator.fetch_create_time(page_file)
                      parsed_text << (create_time ? create_time.strftime(@time_pattern) : sub_script)

                    when 'createdate'
                      create_time = Generator.fetch_create_time(page_file)
                      parsed_text << (create_time ? create_time.strftime(@date_pattern) : sub_script)

                    when 'modifytime'
                      modify_time = Generator.fetch_modify_time(page_file)
                      parsed_text << (modify_time ? modify_time.strftime(@time_pattern) : sub_script)

                    when 'modifydate'
                      modify_time = Generator.fetch_modify_time(page_file)
                      parsed_text << (modify_time ? modify_time.strftime(@date_pattern) : sub_script)

                    when 'link'
                      page_link = get_link(page_file, page_s_variables)
                      parsed_text << (page_link ? page_link : sub_script)

                    else
                      regexp = /^#{form_value}(\p{Blank}?):(.+)$/
                      if page_s_variables
                        value = page_s_variables[regexp, 2]
                      end
                      unless value
                        value = @variables[regexp, 2] if @variables
                      end

                      parsed_text << (value ? value.strip : sub_script)
                  end

                when 'page'
                  puts 'todo : load page'

                else
                  parsed_text << sub_script
              end

              sub_script.clear

            else
              parsed_text << char
            end

          else
            is_valid = is_valid && char.index(/\p{Graph}/)
            if is_valid
              sub_script << char
            else
              parsed_text << sub_script << char
              sub_script.clear
            end
        end
      end

      parsed_text
    end

    def handle_foreach_snippet(foreach_snippet)
      var_name = foreach_snippet[2]
      loop_body = foreach_snippet[4]
      dir_name = foreach_snippet[3].prepend(@page_dir)

      return nil unless Dir.exists? dir_name

      page_ary = Array.new
      Dir.glob("#{dir_name}/**/*") do |page_file|
        page_file = File.expand_path(page_file)
        next if File.directory? page_file
        next unless page_file.end_with? '.md', '.html'

        document = IO.read(page_file)

        next unless document.index(@doc_regexp)

        page_variables = document.split(@doc_regexp)[0].strip
        next if page_variables.empty?

        page_ary.push Page.new(page_file, page_variables)
      end

      page_ary.sort! do |left, right|
        right <=> left
      end

      body_content = ''
      page_ary.each do |page|
        page_snippet = handle_html_content(
            page.instance_variable_get(:@page_file),
            page.instance_variable_get(:@page_variables),
            loop_body, var_name)
        body_content << page_snippet
      end

      body_content.empty? ? nil : body_content
    end

    def extract_page_structure
      document = IO.read(@page_file)

      if document.index(@doc_regexp)
        conary = document.split(@doc_regexp)
        @variables = conary[0]
        @content = conary[1]
      else
        @variables = nil
        @content = document
      end
    end

    def get_link(page_path, variables)
      # only generate link for title-present page
      title = variables[@title_regexp, 3] if variables
      return nil unless title

      relative_loc = page_path[/(\p{Graph}+)\/_pages(\p{Graph}+)/, 2]
      relative_path = File.dirname(relative_loc)
      relative_path << '/' unless relative_path.end_with? '/'

      page_name = variables[produce_variable_regex('slug'), 3]
      return File.expand_path(relative_path << page_name) unless page_name.strip.empty? if page_name

      return relative_loc if relative_loc.end_with? '.html'

      page_name = title
      page_name.gsub!(/[^\p{Alnum}\p{Blank}]/i, '')
      page_name.gsub!(/\p{Blank}/, '-')
      page_name.downcase!
      page_name.strip!

      File.expand_path(relative_path << page_name << '.html')
    end

    def self.fetch_create_time(page_file)
      fetch_git_time(page_file, 'tail')
    end

    def self.fetch_modify_time(page_file)
      fetch_git_time(page_file, 'head')
    end

    def self.fetch_git_time(page_file, cmd)
      Dir.chdir(File.expand_path('..', page_file)) do
        create_time = %x[git log --date=iso --pretty='%cd' #{File.basename(page_file)} | #{cmd} -1]
        Time.parse(create_time)
      end
    end

    class HTML < Redcarpet::Render::HTML
      include Rouge::Plugins::Redcarpet
      def rouge_formatter(opts=nil)
        css_class = opts.fetch(:css_class) if opts
        lexer_tag = css_class[/highlight (\S+)/, 1] if css_class
        lexer_tag ? lexer_tag.prepend(' ') : lexer_tag = ''
        super :css_class => $css_class + lexer_tag, :line_numbers => $line_numbers
      end

      def initialize(opts={})
        # opts.store(:with_toc_data, true)
        # opts.store(:prettify, true)
        opts.store(:xhtml, true)
        super
      end
    end

    def handle_markdown(text)
      markdown = Redcarpet::Markdown.new(HTML, fenced_code_blocks: true, autolink: true, no_intra_emphasis: true, strikethrough: true, tables: true)
      markdown.render(text)
    end

    def produce_variable_regex(var_name)
      /^#{var_name}(\p{Blank}?):(\p{Blank}?)(.+)$/
    end
  end

  class Page
    @page_file
    @page_variables

    def initialize(page_file, page_variables)
      @page_file =  page_file
      @page_variables = page_variables
    end

    def <=> (other)
      regexp = /^sequence(\p{Blank}?):(\p{Blank}?)(\d+)$/

      self_sequence = @page_variables[regexp, 3]
      other_sequence = other.instance_variable_get(:@page_variables)[regexp, 3]
      # puts "self : #{self_sequence} - other : #{other_sequence}"

      # if which one specify sequence, we shall force comparing by sequence.
      if self_sequence || other_sequence
        self_sequence = 0 unless self_sequence
        other_sequence = 0 unless other_sequence

        return -1 if self_sequence.to_i < other_sequence.to_i
        return 0 if self_sequence.to_i == other_sequence.to_i
        return 1 if self_sequence.to_i > other_sequence.to_i
      end


      self_create_time = Generator.fetch_create_time(@page_file)
      other_create_time = Generator.fetch_create_time(other.instance_variable_get(:@page_file))

      return -1 unless self_create_time
      return 1 unless other_create_time
      self_create_time <=> other_create_time
    end

    def to_s
      @page_file
    end
  end
end