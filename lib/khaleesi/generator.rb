module Khaleesi
  class Generator
    class << self
      def list_pages(root_dir)
        @decrt_regexp = /^decorator(\s?):(.+)$/
        @var_regexp = /(\p{Word}+):(\p{Word}+)/
        @doc_regexp = /‡{6,}/
        @root_dir = root_dir

        Dir.glob("#{root_dir}/_pages/**/*") do |page_file|
          @page_file = File.expand_path(page_file)
          next if File.directory? @page_file

          extract_page_structure

          decorator = @variables ? @variables[@decrt_regexp, 2] : nil
          # page can't stand without decorator
          next unless decorator

          parsed_content = parse_markdown_page(decorator) if page_file.end_with? '.md', '.markdown'
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
        parse_html_file("_decorators/#{decorator.strip}.html", content)
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
                  when 'variable'

                    case form_value
                      when 'createtime'
                        create_time = fetch_git_time('tail')
                        parsed_text << create_time

                      when 'modifytime'
                        modify_time = fetch_git_time('head')
                        parsed_text << modify_time

                      else
                        regexp = /^#{form_value}(\s?):(.+)$/
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

        #\s?)\(\$(\p{Alpha}+)\p{Blank}:\p{Blank}\$(\p{Alpha}+)\
        # regexp = /foreach(.+)/
        # puts parsed_text[regexp, 1]
        # puts parsed_text[regexp, 2]
        # puts parsed_text

        parsed_text.sub!(/\$\{decorator:content}/, bore_content)

        # recurse parse the decorator
        decorator = page_s_variables ? page_s_variables[@decrt_regexp, 2] : nil
        decorator ? parse_decorator_file(decorator, parsed_text) : parsed_text
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

      def get_name
        File.basename(@page_file).delete(File.extname(@page_file))
      end

      def get_link
        page_path = @page_file
        while true
          page_path = File.expand_path('..', page_path)
          if page_path.end_with?('_pages')
            page_path = @page_file.split(page_path)[1]
            break
          end
        end

        "#{File.dirname(page_path)}/#{get_name}.html"
      end

      def fetch_git_time(cmd)
        Dir.chdir(File.expand_path('..', @page_file)) do
          create_time = %x[git log --date=iso --pretty='%cd' #{File.basename(@page_file)} | #{cmd} -1]
          Time.parse(create_time).strftime('%a %e %b %H:%M %Y')
        end
      end
    end
  end
end