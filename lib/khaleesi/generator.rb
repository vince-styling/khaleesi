module Khaleesi
  class Generator
    class << self
      def list_pages(root_dir)
        Dir.glob(root_dir + '/_pages/**/*.md') do |page_file|
          parse_page(page_file)
        end
      end

      def parse_page(page_file)
        content = IO.read(page_file)

        puts content.split(/[-]{2,}\s/)[2]
      end
    end
  end
end