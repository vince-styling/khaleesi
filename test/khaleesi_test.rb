require 'test/unit'
require 'khaleesi'

class KhaleesiTest < Test::Unit::TestCase
  def setup
    @opts = {}
  end


  def test_parse_markdown_file_without_linenumbers
    result = Khaleesi::Generator.new(@opts).parse_markdown_file('resources/test_parse_single_file.md')
    assert_equal result.strip, IO.read('resources/test_parse_single_file_without_linenumbers_result')
  end

  def test_parse_markdown_file_enable_line_numbers
    @opts[:line_numbers] = 'true'
    result = Khaleesi::Generator.new(@opts).parse_markdown_file('resources/test_parse_single_file.md')
    assert_equal result.strip, IO.read('resources/test_parse_single_file_enable_linenumbers_result')
  end



  def test_highlighting_code_snippet_without_linenumbers
    highlighting_by_rouge = execute_highlighting

    @opts[:highlighter] = 'pygments'
    highlighting_by_pygments = execute_highlighting

    # both highlighters share an identical structure.
    regexp = /<div class="sourcecode java">(.{0,2})<pre>(.+?)<\/pre>(.{0,2})<\/div>/m
    assert_match regexp, highlighting_by_pygments
    assert_match regexp, highlighting_by_rouge
  end

  def execute_highlighting
    @opts[:css_class] = 'sourcecode'
    Khaleesi::Generator.new(@opts) # just for renew some global variables.
    Khaleesi::Generator::HTML.new.block_code(IO.read('resources/java-samplecode'), 'java')
  end

  def test_highlighting_code_snippet_enable_linenumbers
    @opts[:line_numbers] = 'true'
    highlighting_by_rouge = execute_highlighting

    @opts[:highlighter] = 'pygments'
    highlighting_by_pygments = execute_highlighting

    # both highlighters share an identical structure.
    regexp = /<div class="sourcecode java">(.{0,2})<table><tr><td class="linenos"><pre>(.+?)<\/pre><\/td><td><pre>(.+)<\/pre>(.+)<\/table>(.{0,2})<\/div>/m
    assert_match regexp, highlighting_by_pygments
    assert_match regexp, highlighting_by_rouge
  end



  def test_generate_page_link
    generator = Khaleesi::Generator.new(@opts)

    page_path = "#{Dir.pwd}/_pages/posts/2014/khaleesi.html"

    variables = "name : Khaleesi's introduction\nslug : index.html"
    assert_nil generator.gen_link(page_path, variables)

    variables = "title : Khaleesi's introduction\nslug : index.html"
    assert_equal generator.gen_link(page_path, variables), '/posts/2014/index.html'

    variables = "title : Khaleesi's introduction"
    assert_equal generator.gen_link(page_path, variables), '/posts/2014/khaleesis-introduction.html'


    page_path = "#{Dir.pwd}/_pages/posts/2014/khaleesi.md"
    assert_equal generator.gen_link(page_path, variables), '/posts/2014/khaleesis-introduction.html'

    variables = 'title : 一些事一些情'
    assert_equal generator.gen_link(page_path, variables), '/posts/2014/khaleesi.html'

    page_path = "#{Dir.pwd}/_pages/posts/2014/khaleesi.info.md"
    assert_equal generator.gen_link(page_path, variables), '/posts/2014/khaleesi.info.html'

    page_path = "#{Dir.pwd}/_pages/posts/2014/khaleesi.info.html"
    assert_equal generator.gen_link(page_path, variables), '/posts/2014/khaleesi.info.html'
  end



  def test_format_as_legal_link
    text = 'easily to know and switch the ellipsize mode of textview in Android'
    Khaleesi::Generator.format_as_legal_link(text)
    assert_equal text, 'easily-to-know-and-switch-the-ellipsize-mode-of-textview-in-android'

    text = ' Android : is Google\'s OS for digital devices  ----  stackoverflow '
    Khaleesi::Generator.format_as_legal_link(text)
    assert_equal text, 'android-is-googles-os-for-digital-devices-stackoverflow'

    text = '一些事一些情'
    Khaleesi::Generator.format_as_legal_link(text)
    assert text.empty?
  end



  def test_header_anchor
    $toc_index = 0

    text = 'easily to know and switch the ellipsize mode of textview in Android'
    assert_equal Khaleesi::Generator::HTML.new.header_anchor(text), 'easily-to-know-and-switch-the-ellipsize-mode-of-textview-in-android'

    text = ' Android : is Google\'s OS for digital devices  ----  stackoverflow '
    assert_equal Khaleesi::Generator::HTML.new.header_anchor(text), 'android-is-googles-os-for-digital-devices-stackoverflow'

    text = 'test &quot;unescaping&quot; &#60;&#233;lan&#62; I&#39;m working'
    assert_equal Khaleesi::Generator::HTML.new.header_anchor(text), 'test-unescaping-im-working'

    text = 'Install with <code>RubyGems</code>'
    assert_equal Khaleesi::Generator::HTML.new.header_anchor(text), 'install-with-rubygems'

    text = '一些事一些情'
    assert_equal Khaleesi::Generator::HTML.new.header_anchor(text), 'header-1'

    text = '一些事一些情 : 一些好音乐'
    assert_equal Khaleesi::Generator::HTML.new.header_anchor(text), 'header-2'

    text = ' 一些事一些情 : 一些好音乐  --  双低 '
    assert_equal Khaleesi::Generator::HTML.new.header_anchor(text), 'header-3'
  end



  def test_toc_header_generation
    html = Khaleesi::Generator::HTML.new
    title = 'Introduction of Kahleesi'
    illegal_title = '一些事一些情'

    $toc_index = 0
    $toc_selection = ''
    assert_equal html.header(title, 1), "\n<h1>#{title}</h1>\n"
    assert_equal html.header(title, 2), "\n<h2>#{title}</h2>\n"
    assert_equal html.header(title, 3), "\n<h3>#{title}</h3>\n"
    assert_equal html.header(title, '4'), "\n<h4>#{title}</h4>\n"
    assert_equal html.header(illegal_title, '4'), "\n<h4>#{illegal_title}</h4>\n"

    $toc_index = 0
    $toc_selection = 'h1,h3'
    assert_equal html.header(title, '1'), "\n<h1 id=\"introduction-of-kahleesi\">#{title}</h1>\n"
    assert_equal html.header(illegal_title, 1), "\n<h1 id=\"header-1\">#{illegal_title}</h1>\n"
    assert_equal html.header(title, 2), "\n<h2>#{title}</h2>\n"
    assert_equal html.header(title, 3), "\n<h3 id=\"introduction-of-kahleesi\">#{title}</h3>\n"
    assert_equal html.header(illegal_title, '3'), "\n<h3 id=\"header-2\">#{illegal_title}</h3>\n"
    assert_equal html.header(title, '4'), "\n<h4>#{title}</h4>\n"

    $toc_index = 0
    $toc_selection = 'h1,h2[unique]'
    assert_equal html.header(title, '1'), "\n<h1 id=\"header-1\">#{title}</h1>\n"
    assert_equal html.header(title, 2), "\n<h2 id=\"header-2\">#{title}</h2>\n"
    assert_equal html.header(illegal_title, 2), "\n<h2 id=\"header-3\">#{illegal_title}</h2>\n"
    assert_equal html.header(title, 3), "\n<h3>#{title}</h3>\n"
    assert_equal html.header(title, '4'), "\n<h4>#{title}</h4>\n"
  end
end