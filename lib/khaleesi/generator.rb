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
      @variable_stack = Array.new
      start_time = Time.now

      @page_stack = Array.new

      Dir.glob("#{@page_dir}/**/*") do |page_file|
        next unless File.readable? page_file
        next unless is_valid_file page_file

        @page_stack.clear
        @page_stack.push File.expand_path(page_file)
        single_start_time = Time.now

        if @diff_plus
          file_status = nil
          base_name = File.basename(page_file)
          Dir.chdir(File.expand_path('..', page_file)) do
            file_status = %x[git status -s #{base_name} 2>&1]
          end
          file_status = file_status.to_s.strip

          # only haven't commit pages available, Git will return nothing if page committed.
          next if file_status.empty?

          # a correct message from Git should included the file name, may occur errors
          # in command running such as Git didn't install if not include.
          unless file_status.include? base_name
            puts file_status
            next
          end
        end

        extract_page_structure(page_file)

        variables = @variable_stack.pop
        # page can't stand without decorator
        next unless variables and variables[@decrt_regexp, 3]

        # isn't legal page if title missing
        next unless variables[@title_regexp, 3]

        content = is_html_file(page_file) ? parse_html_file(page_file, '') : parse_markdown_file(page_file)

        page_path = File.expand_path(@dest_dir + get_link(page_file, variables))
        page_dir_path = File.dirname(page_path)
        unless File.directory?(page_dir_path)
          FileUtils.mkdir_p(page_dir_path)
        end

        bytes = IO.write(page_path, content)
        puts "Done (#{Generator.humanize(Time.now - single_start_time)}) => '#{page_path}' bytes[#{bytes}]."
      end

      puts "\nGenerator time elapsed : #{Generator.humanize(Time.now - start_time)}."
    end

    def parse_markdown_file(file_path)
      content = extract_page_structure(file_path)
      content = parse_decorator_file(handle_markdown(content))
      @variable_stack.pop
      content
    end

    def parse_decorator_file(bore_content)
      variables = @variable_stack.last
      decorator = variables ? variables[@decrt_regexp, 3] : nil
      decorator ? parse_html_file("#{@src_dir}/_decorators/#{decorator.strip}.html", bore_content) : bore_content
    end

    def parse_html_file(file_path, bore_content)
      content = extract_page_structure(file_path)

      content = parse_html_content(content.to_s, bore_content)
      content = parse_decorator_file(content) # recurse parse

      @variable_stack.pop
      content
    end

    def parse_html_content(html_content, bore_content)
      parsed_text = handle_html_content(html_content, '')


      # http://www.ruby-doc.org/core-2.1.0/Regexp.html#class-Regexp-label-Repetition use '.+?' to disable greedy match.
      regexp = /(#foreach\p{Blank}?\(\$(\p{Graph}+)\p{Blank}?:\p{Blank}?\$(\p{Graph}+)([^\)]*)\)(.+?)#end)/m
      while (foreach_snippet = parsed_text.match(regexp))
        foreach_snippet = handle_foreach_snippet(foreach_snippet)

        # because the Regexp cannot skip a unhandled foreach snippet,
        # so we claim every snippet must successful, and if not, we shall use blank as replacement.
        parsed_text.sub!(regexp, foreach_snippet.to_s)
      end


      regexp = /(#if\p{Blank}?chain:(prev|next)\(\$(\p{Graph}+)\)(.+?)#end)/m
      while (chain_snippet = parsed_text.match(regexp))
        chain_snippet = handle_chain_snippet(chain_snippet)
        parsed_text.sub!(regexp, chain_snippet.to_s)
      end


      parsed_text.sub!(/\$\{decorator:content}/, bore_content)

      parsed_text
    end

    def handle_html_content(html_content, added_scope)
      page_file = @page_stack.last
      parsed_text = ''
      sub_script = ''

      html_content.each_char do |char|
        is_valid = sub_script.start_with?('${')
        case char
          when '$'
            parsed_text << sub_script unless sub_script.empty?
            sub_script.clear << char

          when '{', ':'
            is_valid = sub_script.eql? '$' if char == '{'
            is_valid = is_valid && sub_script.length > 3 if char == ':'
            if is_valid
              sub_script << char
            else
              parsed_text << sub_script << char
              sub_script.clear
            end

          when '}'
            is_valid = is_valid && sub_script.length > 4
            sub_script << char
            if is_valid

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
                      page_link = get_link(page_file, @variable_stack.last)
                      parsed_text << (page_link ? page_link : sub_script)

                    else
                      text = nil
                      if form_value.eql?('content') and form_scope.eql?(added_scope)
                        text = parse_html_file(page_file, '') if is_html_file(page_file)
                        text = parse_markdown_file(page_file) if is_markdown_file(page_file)

                      else
                        regexp = /^#{form_value}(\p{Blank}?):(.+)$/
                        @variable_stack.reverse_each do |var|
                          text = var[regexp, 2] if var
                          break if text
                        end

                      end

                      parsed_text << (text ? text.strip : sub_script)

                  end

                when 'page'
                  match_page = nil
                  Dir.glob("#{@page_dir}/**/#{form_value}.*") do |inner_page|
                    match_page = inner_page
                    break
                  end

                  if is_html_file(match_page)
                    @page_stack.push match_page
                    inc_content = parse_html_file(match_page, '')
                    @page_stack.pop
                  end
                  inc_content = parse_markdown_file(match_page) if is_markdown_file(match_page)

                  parsed_text << (inc_content ? inc_content : sub_script)

                else
                  parsed_text << sub_script
              end

            else
              parsed_text << sub_script
            end

            sub_script.clear

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
      dir_path = foreach_snippet[3].prepend(@page_dir)
      return unless Dir.exists? dir_path

      page_ary = take_page_array(dir_path)
      loop_body = foreach_snippet[5]
      var_name = foreach_snippet[2]

      sub_terms = foreach_snippet[4].to_s.strip.match(/(asc|desc)?\p{Blank}?(\d)*/)
      order_by = sub_terms[1].to_s
      limit = sub_terms[2].to_i
      limit = -1 if limit == 0

      page_ary.reverse! if order_by.eql?('desc')

      parsed_body = ''
      page_ary.each_with_index do |page, index|
        break if index == limit
        @variable_stack.push(page.instance_variable_get(:@page_variables))
        @page_stack.push page.to_s

        parsed_body << handle_html_content(loop_body, var_name)

        @variable_stack.pop
        @page_stack.pop
      end

      parsed_body unless parsed_body.empty?
    end

    def handle_chain_snippet(chain_snippet)
      cmd = chain_snippet[2]
      var_name = chain_snippet[3]
      loop_body = chain_snippet[4]

      page_ary = take_page_array(File.expand_path('..', @page_stack.first))
      page_ary.each_with_index do |page, index|
        next unless page.to_s.eql? @page_stack.first

        page_file = cmd.eql?('prev') ? page_ary.prev(index) : page_ary.next(index)
        return unless page_file

        @variable_stack.push(page_file.instance_variable_get(:@page_variables))
        @page_stack.push page_file.to_s

        parsed_body = handle_html_content(loop_body, var_name)

        @variable_stack.pop
        @page_stack.pop

        return parsed_body
      end
      nil
    end

    def take_page_array(dir_path)
      page_ary = Array.new
      Dir.glob("#{dir_path}/**/*") do |page_file|
        next unless is_valid_file(page_file)

        extract_page_structure(page_file)
        page_ary.push Page.new(page_file, @variable_stack.pop)
      end

      page_ary.sort! do |left, right|
        right <=> left
      end
    end

    def extract_page_structure(page_file)
      document = IO.read(page_file)

      if document.index(@doc_regexp)
        conary = document.split(@doc_regexp)
        @variable_stack.push(conary[0])
        conary[1]
      else
        @variable_stack.push(nil)
        document
      end
    end

    def get_link(page_path, variables)
      # only generate link for title-present page.
      title = variables[@title_regexp, 3] if variables
      return unless title

      relative_loc = page_path[/(\p{Graph}+)\/_pages(\p{Graph}+)/, 2]
      relative_path = File.dirname(relative_loc)
      relative_path << '/' unless relative_path.end_with? '/'

      page_name = variables[produce_variable_regex('slug'), 3]
      return File.expand_path(relative_path << page_name) unless page_name.strip.empty? if page_name

      return relative_loc if is_html_file(relative_loc)

      page_name = title
      page_name.gsub!(/[^\p{Alnum}\p{Blank}_]/i, '')
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
        commit_time = %x[git log --date=iso --pretty='%cd' #{File.basename(page_file)} 2>&1 | #{cmd} -1]
        begin
          Time.parse(commit_time)
        rescue
          Time.now
        end
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
      return '' if text.to_s.empty?
      markdown = Redcarpet::Markdown.new(HTML, fenced_code_blocks: true, autolink: true, no_intra_emphasis: true, strikethrough: true, tables: true)
      markdown.render(text)
    end

    def produce_variable_regex(var_name)
      /^#{var_name}(\p{Blank}?):(\p{Blank}?)(.+)$/
    end

    def is_valid_file(file_path)
      is_markdown_file(file_path) or is_html_file(file_path)
    end

    def is_markdown_file(file_path)
      file_path and file_path.end_with? '.md'
    end

    def is_html_file(file_path)
      file_path and file_path.end_with? '.html'
    end

    def self.humanize(secs) # http://stackoverflow.com/a/4136485/1294681
      secs = secs * 1000
      [[1000, :milliseconds], [60, :seconds], [60, :minutes]].map { |count, name|
        if secs > 0
          secs, n = secs.divmod(count)
          n.to_i > 0 ? "#{n.to_i} #{name}" : ''
        end
      }.compact.reverse.join(' ').squeeze(' ').strip
    end
  end

  class Page
    @page_file
    @page_variables

    def initialize(page_file, page_variables)
      @page_file = File.expand_path(page_file)
      @page_variables = page_variables
    end

    def <=> (other)
      regexp = /^sequence(\p{Blank}?):(\p{Blank}?)(\d+)$/

      self_sequence = @page_variables[regexp, 3] if @page_variables
      o_variables = other.instance_variable_get(:@page_variables)
      other_sequence = o_variables[regexp, 3] if o_variables

      # if which one specify sequence, we shall force comparing by sequence.
      if self_sequence || other_sequence
        self_sequence = 0 unless self_sequence
        other_sequence = 0 unless other_sequence

        return 1 if self_sequence < other_sequence
        return 0 if self_sequence == other_sequence
        return -1 if self_sequence > other_sequence
      end


      other_create_time = other.take_create_time
      self_create_time = take_create_time
      other_create_time <=> self_create_time
    end

    @create_time
    def take_create_time
      # cache the create time to improve performance.
      return @create_time if @create_time
      @create_time = Generator.fetch_create_time(@page_file)
    end

    def to_s
      @page_file
    end
  end

  class Array < Array
    def next(index)
      index += 1
      index < size ? at(index) : nil
    end
    def prev(index)
      index > 0 ? at(index - 1) : nil
    end
  end
end