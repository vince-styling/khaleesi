module Khaleesi
  class Generator
    class << self
      def list_pages(root_dir)
        @decrt_regexp = /^decorator(\s*):(.+)$/
        @var_regexp = /(\p{Word}+):(\p{Word}+)/
        @doc_regexp = /‡{3,}/
        @root_dir = root_dir

        Dir.glob("#{root_dir}/_pages/**/*") do |page_file|
          @page_file = File.expand_path(page_file)
          parsed_content = parse_markdown_page if page_file.end_with?('.md')
          parsed_content = parse_html_page if page_file.end_with?('.html')
          puts parsed_content
        end
      end

      def parse_html_page
        extract_page_structure
        parse_decorator_file(@variables, @content)
      end

      def parse_markdown_page
        extract_page_structure

        decorator = @variables[@decrt_regexp, 2] if @variables
        # markdown page can't stand without decorator
        return @content unless decorator

        @content = Khaleesi.handle_markdown(@content)
        parse_decorator_file(@variables, @content)
      end

      def parse_decorator_file(variables, content)
        decorator = variables[@decrt_regexp, 2] if variables
        decorator ? parse_html_file("_decorators/#{decorator.strip}.html", content) : content
      end

      def parse_html_file(sub_path, bore_content)
        decorator = IO.read("#{@root_dir}/#{sub_path}")

        if decorator.index(@doc_regexp)
          conary = decorator.split(@doc_regexp)
          decorator_s_variables = conary[0]
          decorator_s_content = conary[1]
        else
          decorator_s_content = decorator
        end

        parsed_text = ''
        sub_script = ''

        decorator_s_content.each_char do |char|
          case char
            when '$'
              sub_script.clear << char

            when '{'
              is_valid = sub_script.eql? '$'
              sub_script << char if is_valid
              parsed_text << char unless is_valid

            when ':'
              is_valid = sub_script.start_with?('${') && sub_script.length > 3
              sub_script << char if is_valid
              parsed_text << char unless is_valid

            when '}'
              is_valid = sub_script.start_with?('${') && sub_script.length > 4
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
                        regexp = /^#{form_value}(\s*):(.+)$/
                        if decorator_s_variables
                          value = decorator_s_variables[regexp, 2]
                        end
                        unless value
                          value = @variables[regexp, 2] if @variables
                        end

                        value ? parsed_text << value.strip : parsed_text << sub_script
                    end

                  when 'decorator'
                    is_valid = form_value.eql? 'content'
                    is_valid ? parsed_text << bore_content : parsed_text << sub_script

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
              is_valid = sub_script.start_with?('${') && char.index(/\p{Graph}/)
              if is_valid
                sub_script << char
              else
                parsed_text << sub_script << char
                sub_script.clear
              end
          end
        end

        # recurse parse the decorator
        parse_decorator_file(decorator_s_variables, parsed_text)
      end

      def extract_page_structure
        document = IO.read(@page_file)

        conary = document.split(@doc_regexp)
        @variables = conary[0].strip
        @content = conary[1].strip
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