require 'Khaleesi'

def construct
  Khaleesi::Generator.new(
      '/Users/vince/dev/vince_blog/vincestyling.github.com/', '/Users/vince/dev/vince_blog/site/',
      'false', 'highlight', '%a %e %b %H:%M %Y', '%F', 'false', '', ''
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

# test_generator_all



def test_pygemnts
  # puts Pygments.css(:style => 'emacs')

  code = File.read('samplecode.java')
  # puts Pygments.highlight(code, :lexer => 'java')
  puts Pygments.highlight(code, :lexer => 'java', :options => {:cssclass => 'lingyunxiao', :linenos => true})
end

# test_pygemnts



def test_format_as_legal_link
  text = 'easily to know and switch the ellipsize mode of textview in Android'
  Khaleesi::Generator.format_as_legal_link(text)
  p text

  text = 'Android : is Google\'s OS for digital devices  ----  stackoverflow'
  Khaleesi::Generator.format_as_legal_link(text)
  p text

  text = '一些事一些情'
  Khaleesi::Generator.format_as_legal_link(text)
  p text
end

# test_format_as_legal_link



def test_header_anchor
  $toc_index = 0

  text = 'easily to know and switch the ellipsize mode of textview in Android'
  p Khaleesi::Generator::HTML.new.header_anchor(text)

  text = 'Android : is Google\'s OS for digital devices  ----  stackoverflow'
  p Khaleesi::Generator::HTML.new.header_anchor(text)

  text = 'test &quot;unescaping&quot; &#60;&#233;lan&#62; I&#39;m working'
  p Khaleesi::Generator::HTML.new.header_anchor(text)

  text = 'Install with <code>RubyGems</code>'
  p Khaleesi::Generator::HTML.new.header_anchor(text)

  text = '一些事一些情'
  p Khaleesi::Generator::HTML.new.header_anchor(text)

  text = '一些事一些情 : 一些好音乐'
  p Khaleesi::Generator::HTML.new.header_anchor(text)

  text = '一些事一些情 : 一些好音乐  --  双低'
  p Khaleesi::Generator::HTML.new.header_anchor(text)
end

# test_header_anchor



def test_toc_header_generation
  title = 'Introduction of Kahleesi'
  $toc_index = 0

  $toc_selection = nil
  p Khaleesi::Generator::HTML.new.header(title, 1)
  p Khaleesi::Generator::HTML.new.header(title, 2)
  p Khaleesi::Generator::HTML.new.header(title, 3)
  p Khaleesi::Generator::HTML.new.header(title, '4')

  $toc_selection = 'h1,h3'
  p Khaleesi::Generator::HTML.new.header(title, '1')
  p Khaleesi::Generator::HTML.new.header(title, 2)
  p Khaleesi::Generator::HTML.new.header(title, 3)
  p Khaleesi::Generator::HTML.new.header(title, '4')

  $toc_selection = 'h1,h2[unique]'
  p Khaleesi::Generator::HTML.new.header(title, '1')
  p Khaleesi::Generator::HTML.new.header(title, 2)
  p Khaleesi::Generator::HTML.new.header(title, 3)
  p Khaleesi::Generator::HTML.new.header(title, '4')
end

test_toc_header_generation
