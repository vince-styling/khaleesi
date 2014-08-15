require 'Khaleesi'

def test_parse_single_file
  file = File.read('/Users/vince/dev/git_marked/README.md')
  Khaleesi.handle_markdown(file)
end

# puts test_parse_single_file


def test_generator_all
  Khaleesi::Generator.new(
      '/Users/vince/dev/vince_blog/vincestyling.github.com/', '/Users/vince/dev/vince_blog/site/',
      'true', 'highlight', '%a %e %b %H:%M %Y'
  ).build_all
end

test_generator_all