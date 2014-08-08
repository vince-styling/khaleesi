require 'Khaleesi'

def test_parse_single_file
  file = File.read('/Users/vince/dev/git_marked/README.md')
  Khaleesi.handle_markdown(file)
end

# puts test_parse_single_file


def test_generator
  Khaleesi::Generator.list_pages('/Users/vince/dev/vince_blog/vincestyling.github.com/')
end

test_generator