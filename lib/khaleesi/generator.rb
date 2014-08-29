module Khaleesi
  class Generator

    # The constructor accepts all settings then keep them as fields, lively in whole processing job.
    def initialize(src_dir, dest_dir, line_numbers, css_class, time_pattern, date_pattern, diff_plus, highlighter)
      # source directory path (must absolutely).
      @src_dir = src_dir

      # destination directory path (must absolutely).
      @dest_dir = dest_dir

      # setting to tell Rouge output line numbers.
      $line_numbers = line_numbers.eql?('true')

      # a css class name which developer wants to customizable.
      $css_class = css_class

      # a full time pattern used to including date and time like '2014-08-22 16:45'.
      # see http://www.ruby-doc.org/core-2.1.2/Time.html#strftime-method for pattern details.
      @time_pattern = time_pattern

      # a short time pattern used to display only date like '2014-08-22'.
      @date_pattern = date_pattern

      # we just pick on those pages who changed but haven't commit
      # to git repository to generate, ignore the unchanged pages.
      # this action could be a huge benefit when you were creating
      # a new page and you want just to see what was she like at final.
      @diff_plus = diff_plus.eql?('true')

      # indicating which syntax highlighter would be used, default is Rouge.
      $use_pygments = highlighter.eql?('pygments')
    end

    # Main entry of Generator that generates all the pages of the site,
    # it scan the source directory files that fulfill the rule of page,
    # evaluates and applies all predefine logical, writes the final
    # content into destination directory cascaded.
    def generate
      @decrt_regexp = produce_variable_regex('decorator')
      @title_regexp = produce_variable_regex('title')
      @var_regexp = /(\p{Word}+):(\p{Word}+)/
      @doc_regexp = /‡{6,}/

      @page_dir = "#{@src_dir}/_pages/"
      start_time = Time.now

      # a cascaded variable stack that storing a set of page's variable while generating,
      # able for each handling page to grab it parent's variable and parent's variable.
      @variable_stack = Array.new

      # a queue that storing valid pages, use to avoid invalid page(decorator file)
      # influence the page link, page times generation.
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

        page_path = File.expand_path(@dest_dir + gen_link(page_file, variables))
        page_dir_path = File.dirname(page_path)
        unless File.directory?(page_dir_path)
          FileUtils.mkdir_p(page_dir_path)
        end

        bytes = IO.write(page_path, content)
        puts "Done (#{Generator.humanize(Time.now - single_start_time)}) => '#{page_path}' bytes[#{bytes}]."
      end

      puts "Generator time elapsed : #{Generator.humanize(Time.now - start_time)}."
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
      regexp = /(#foreach\p{Blank}?\(\$(\p{Graph}+)\p{Blank}?:\p{Blank}?\$(\p{Graph}+)\p{Blank}?(asc|desc)?\p{Blank}?(\d*)\)(.+?)#end)/m
      while (foreach_snippet = parsed_text.match(regexp))
        foreach_snippet = handle_foreach_snippet(foreach_snippet)

        # because the Regexp cannot skip a unhandled foreach snippet,
        # so we claim every snippet must done successfully,
        # and if not, we shall use blank as replacement.
        parsed_text.sub!(regexp, foreach_snippet.to_s)
      end


      regexp = /(#if\p{Blank}chain:(prev|next)\(\$(\p{Graph}+)\)(.+?)#end)/m
      while (chain_snippet = parsed_text.match(regexp))
        chain_snippet = handle_chain_snippet(chain_snippet)
        parsed_text.sub!(regexp, chain_snippet.to_s)
      end


      # we deal with decorator's content at final because it may slow down
      # the process even cause errors for the "foreach" and "chain" scripts.
      parsed_text.sub!(/\$\{decorator:content}/, bore_content)

      parsed_text
    end

    def handle_html_content(html_content, added_scope)
      page_file = @page_stack.last
      parsed_text = ''
      sub_script = ''

      # char by char to evaluate html content.
      html_content.each_char do |char|
        is_valid = sub_script.start_with?('${')
        case char
          when '$'
            # if met the variable expression beginner, we'll append precede characters to parsed_text
            # so the invalid part of expression still output as usual text rather than erase them.
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

              # parsing variable expressions such as :
              # ${variable:title}, ${variable:description}, ${custom_scope:custom_value} etc.
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
                      page_link = gen_link(page_file, @variable_stack.last)
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

    # Foreach loop was design for traversal all files of directory which inside the "_pages" directory,
    # each time through the loop, the segment who planning to repeat would be evaluate and output as parsed text.
    # at the beginning, we'll gather all files and sort by sequence or create time finally produce an ordered list.
    # NOTE: sub-directory writing was acceptable, also apply order-by-limit mode like SQL to manipulate that list.
    #
    # examples :
    #
    # loop the whole list :
    # <ul>
    #   #foreach ($theme : $themes)
    #     <li>${theme:name}</li>
    #     <li>${theme:description}</li>
    #   #end
    # </ul>
    #
    # loop the whole list but sortby descending and limit 5 items.
    # <ul>
    #   #foreach ($theme : $themes desc 5)
    #     <li>${theme:name}</li>
    #     <li>${theme:description}</li>
    #   #end
    # </ul>
    def handle_foreach_snippet(foreach_snippet)
      dir_path = foreach_snippet[3].prepend(@page_dir)
      return unless Dir.exists? dir_path

      loop_body = foreach_snippet[6]
      var_name = foreach_snippet[2]
      order_by = foreach_snippet[4]
      limit = foreach_snippet[5].to_i
      limit = -1 if limit == 0

      page_ary = take_page_array(dir_path)
      # if sub-term enable descending order, we'll reversing the page stack.
      page_ary.reverse! if order_by.eql?('desc')

      parsed_body = ''
      page_ary.each_with_index do |page, index|
        # abort loop if has limitation.
        break if index == limit
        parsed_body << handle_snippet_page(page, loop_body, var_name)
      end
      parsed_body
    end

    # Chain, just as its name meaning, we take the previous or next page from the ordered list
    # which same of foreach snippet, of course that list contained current page we just
    # generating on, so we took the near item for it, just make it like a chain.
    #
    # examples :
    #
    # #if chain:prev($theme)
    #   <div class="prev">Prev Theme : <a href="${theme:link}">${theme:title}</a></div>
    # #end
    #
    # #if chain:next($theme)
    #   <div class="next">Next Theme : <a href="${theme:link}">${theme:title}</a></div>
    # #end
    def handle_chain_snippet(chain_snippet)
      cmd = chain_snippet[2]
      var_name = chain_snippet[3]
      loop_body = chain_snippet[4]

      page_ary = take_page_array(File.expand_path('..', @page_stack.first))
      page_ary.each_with_index do |page, index|
        next unless page.to_s.eql? @page_stack.first

        page = cmd.eql?('prev') ? page_ary.prev(index) : page_ary.next(index)
        return page ? handle_snippet_page(page, loop_body, var_name) : nil
      end
      nil
    end

    def handle_snippet_page(page, loop_body, var_name)
      # make current page properties occupy atop for two stacks while processing such sub-level files.
      @variable_stack.push(page.instance_variable_get(:@page_variables))
      @page_stack.push page.to_s

      parsed_body = handle_html_content(loop_body, var_name)

      # abandon that properties immediately.
      @variable_stack.pop
      @page_stack.pop

      parsed_body
    end

    # Search that directory and it's sub-directories, collecting all valid files,
    # then sorting by sequence or create time before return.
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

    # Split by separators, extract page's variables and content.
    def extract_page_structure(page_file)
      document = IO.read(page_file)

      if document.index(@doc_regexp)
        conary = document.split(@doc_regexp)
        @variable_stack.push(conary[0])
        conary[1]
      else
        # we must hold the variable stack.
        @variable_stack.push(nil)
        document
      end
    end

    def gen_link(page_path, variables)
      # only generate link for title-present page.
      title = variables[@title_regexp, 3] if variables
      return unless title

      relative_loc = page_path[/(\p{Graph}+)\/_pages(\p{Graph}+)/, 2]
      relative_path = File.dirname(relative_loc)
      relative_path << '/' unless relative_path.end_with? '/'

      # fetch and use the pre-define page name if legal.
      page_name = variables[produce_variable_regex('slug'), 3]
      return File.expand_path(relative_path << page_name) unless page_name.strip.empty? if page_name

      # use the file name if was html file.
      return relative_loc if is_html_file(relative_loc)

      # we shall use the page title to generating a link.
      page_name = title
      # delete else characters if not [alpha,number,underscore].
      page_name.gsub!(/[^\p{Alnum}\p{Blank}_]/i, '')
      # replace [blank] to dashes.
      page_name.gsub!(/\p{Blank}/, '-')
      page_name.downcase!
      page_name.strip!

      File.expand_path(relative_path << page_name << '.html')
    end

    def self.fetch_create_time(page_file)
      # fetch the first Git versioned time as create time.
      fetch_git_time(page_file, 'tail')
    end

    def self.fetch_modify_time(page_file)
      # fetch the last Git versioned time as modify time.
      fetch_git_time(page_file, 'head')
    end

    # Enter into the file container and take the Git time,
    # if something wrong with executing(Git didn't install?),
    # we'll use current time as replacement.
    def self.fetch_git_time(page_file, cmd)
      Dir.chdir(File.expand_path('..', page_file)) do
        commit_time = %x[git log --date=iso --pretty='%cd' #{File.basename(page_file)} 2>&1 | #{cmd} -1]
        begin
          # the rightful time looks like this : "2014-08-18 18:44:41 +0800"
          Time.parse(commit_time)
        rescue
          Time.now
        end
      end
    end

    # intercept the Redcarpet processing, do the syntax highlighter with Rouge or Pygments.
    class HTML < Redcarpet::Render::HTML
      def block_code(code, language)
        language = 'text' if language.to_s.strip.empty?
        css_class = $css_class + ' ' + language
        return pygments_colorize(css_class, code, language) if $use_pygments
        rouge_colorize(css_class, code, language)
      end

      def pygments_colorize(css_class, code, language)
        colored_html = Pygments.highlight(code, :lexer => language, :options => {:cssclass => css_class, :linenos => $line_numbers})
        return colored_html unless $line_numbers

        # we'll have the html structure consistent whatever line numbers present or not.
        colored_html.sub!(" class=\"#{css_class}table\"", '')
        colored_html.sub!('<div class="linenodiv">', '')
        colored_html.sub!('</div>', '')
        colored_html.sub!(' class="code"', '')
        root_elements = "<div class=\"#{css_class}\">"
        colored_html.sub!(root_elements, '')
        colored_html.prepend(root_elements).concat('</div>')
        colored_html
      end

      def rouge_colorize(css_class, code, language)
        formatter = Rouge::Formatters::HTML.new(:css_class => css_class, :line_numbers => $line_numbers)
        lexer = Rouge::Lexer.find_fancy(language, code) || Rouge::Lexers::PlainText
        formatter.format(lexer.lex(code))
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
        self_sequence = self_sequence.to_i
        other_sequence = other_sequence.to_i

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
      # cache the create time to improve performance while sorting by.
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