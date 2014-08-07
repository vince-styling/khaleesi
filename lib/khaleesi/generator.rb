module Khaleesi
  class Generator
    class << self
      def list_pages(root_dir)
        Dir.glob(root_dir + '/_pages/**/*.md') do |page_file|
          parse_page(page_file)
        end
      end

      def parse_page(page_file)
        document = IO.read(page_file)

        variables = ''
        content = ''
        jump = 0
        document.each_line {|line|
          if jump == 0
            if line.strip == '---'
              jump = 1
            end
          elsif jump == 1
            if line.strip == '---'
              jump = 2
            else
              variables.concat(line)
            end
          elsif jump == 2
            content.concat(line)
          end
        }

        puts variables
      end
    end
  end
end