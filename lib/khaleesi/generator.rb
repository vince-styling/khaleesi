module Khaleesi
  class Generator
    class << self
      @doc_regexp
      @var_regexp

      @root_dir

      def list_pages(root_dir)
        @doc_regexp = /‡{3,}/
        @var_regexp = /(\p{Word}+):(\p{Word}+)/
        @root_dir = root_dir

        Dir.glob("#{root_dir}/_pages/**/*.md") do |page_file|
          @page_file = File.expand_path(page_file)
          parse_markdown_page
        end
      end

      def parse_markdown_page
        parse_page

        decorator = @variables[/^decorator(\s*):(.+)$/, 2]

        # markdown file can't stand without decorator
        return unless decorator
        decorator.strip!

        decorator = IO.read("#{@root_dir}/_decorators/#{decorator}.html")

        conary = decorator.split(@doc_regexp)
        decorator_s_variables = conary[0]
        decorator_s_content = conary[1]
        decorator_s_content = decorator unless decorator_s_variables

        parse_text = ''
        sub_script = ''

        decorator_s_content.each_char do |char|
          case char
            when '$'
              sub_script.clear << char

            when '{'
              is_valid = sub_script.eql? '$'
              sub_script << char if is_valid
              parse_text << char unless is_valid

            when ':'
              is_valid = sub_script.start_with?('${') && sub_script.length > 3
              sub_script << char if is_valid
              parse_text << char unless is_valid

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
                        parse_text << create_time
                      when 'modifytime'
                        modify_time = fetch_git_time('head')
                        parse_text << modify_time
                      when 'identifier'
                        puts 'identifier'
                      else
                        regexp = /^#{form_value}(\s*):(.+)$/
                        value = ''
                        if decorator_s_variables
                          value = decorator_s_variables[regexp, 2]
                        end
                        unless value
                          value = @variables[regexp, 2] if @variables
                        end

                        value ? parse_text << value.strip : parse_text << sub_script
                    end

                  when 'decorator'
                    is_valid = form_value.eql? 'content'
                    parse_text << Khaleesi.handle_markdown(@content) if is_valid
                    parse_text << sub_script unless is_valid

                  when 'page'
                    puts 'todo : load page'

                  else
                    parse_text << sub_script
                end

                sub_script.clear

              else
                parse_text << char
              end

            else
              is_valid = sub_script.start_with?('${') && char.index(/\p{Graph}/)
              if is_valid
                sub_script << char
              else
                parse_text << sub_script << char
                sub_script.clear
              end
          end
        end

        # puts parse_text
      end

      @@page_file
      @@variables
      @@content

      def parse_page
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