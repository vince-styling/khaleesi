module Khaleesi
  class Generator
    class << self
      def list_pages(root_dir, time_pattern)
        @decrt_regexp = /^decorator(\p{Blank}?):(\p{Blank}?)(.+)$/
        @var_regexp = /(\p{Word}+):(\p{Word}+)/
        @doc_regexp = /‡{6,}/

        @time_pattern = time_pattern
        @root_dir = root_dir
        @page_dir = "#{root_dir}/_pages/"

        Dir.glob("#{@page_dir}/**/*") do |page_file|
          @page_file = File.expand_path(page_file)
          next if File.directory? @page_file

          extract_page_structure

          decorator = @variables ? @variables[@decrt_regexp, 3] : nil
          # page can't stand without decorator
          next unless decorator

          parsed_content = parse_markdown_page(decorator) if page_file.end_with? '.md'
          parsed_content = parse_html_page(decorator) if page_file.end_with? '.html'

          puts parsed_content
        end
      end

      def parse_html_page(decorator)
        @content = parse_html_content(nil, @content, '')
        parse_decorator_file(decorator, @content)
      end

      def parse_markdown_page(decorator)
        @content = Khaleesi.handle_markdown(@content)
        parse_decorator_file(decorator, @content)
      end

      def parse_decorator_file(decorator, content)
        parse_html_file("_decorators/#{decorator}.html", content)
      end

      def parse_html_file(sub_path, bore_content)
        html_content = IO.read("#{@root_dir}/#{sub_path}")

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
                        create_time = fetch_create_time(page_file)
                        parsed_text << (create_time ? create_time.strftime(@time_pattern) : sub_script)

                      when 'modifytime'
                        modify_time = fetch_modify_time(page_file)
                        parsed_text << (modify_time ? modify_time.strftime(@time_pattern) : sub_script)

                      when 'link'
                        page_link = get_link(page_file, page_s_variables)
                        parsed_text << (page_link ? File.expand_path(page_link) : sub_script)

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
        dir_name = foreach_snippet[3]
        loop_body = foreach_snippet[4]

        dir_name.prepend('posts/') unless dir_name.eql? 'posts'
        dir_name << '/'
        dir_name.prepend(@page_dir)

        return nil unless File.exists? dir_name

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
        relative_name = page_path[/(\p{Graph}+)\/_pages(\p{Graph}+)/, 2]
        relative_path = File.dirname(relative_name) << '/'

        page_name = variables[/^slug(\p{Blank}?):(\p{Blank}?)(.+)$/, 3]
        return relative_path << page_name unless page_name.strip.empty? if page_name

        page_name = variables[/^title(\p{Blank}?):(\p{Blank}?)(.+)$/, 3]
        page_name.gsub!(/[^\p{Alnum}\p{Blank}]/i, '')
        page_name.gsub!(/\p{Blank}/, '-')
        page_name.downcase!
        page_name.strip!

        relative_path << page_name << '.html'
      end

      def fetch_create_time(page_file)
        fetch_git_time(page_file, 'tail')
      end

      def fetch_modify_time(page_file)
        fetch_git_time(page_file, 'head')
      end

      def fetch_git_time(page_file, cmd)
        Dir.chdir(File.expand_path('..', page_file)) do
          create_time = %x[git log --date=iso --pretty='%cd' #{File.basename(page_file)} | #{cmd} -1]
          Time.parse(create_time)
        end
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
end