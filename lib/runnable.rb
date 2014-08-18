require 'Khaleesi'

def construct
  Khaleesi::Generator.new(
      '/Users/vince/dev/vince_blog/vincestyling.github.com/', '/Users/vince/dev/vince_blog/site/',
      'false', 'highlight', '%a %e %b %H:%M %Y', '%F', 'false'
  )
end

def test_parse_single_file
  file = File.read('/Users/vince/dev/netroid/docs/_pages/request.md')
  construct.handle_markdown(file)
end

# puts test_parse_single_file

def test_generator_all
  construct.generate
end

test_generator_all