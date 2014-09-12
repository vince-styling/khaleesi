require 'test/unit'
require 'khaleesi'

class KhaleesiCommandsTest < Test::Unit::TestCase
  def test_the_khaleesi_produce_command
    result = %x[khaleesi produce resources/test_parse_single_file.md 2>&1]
    assert result.end_with?(IO.read('resources/test_parse_single_file_without_linenumbers_result'))
  end

  def test_the_khaleesi_construction_command
    site_name = 'mysite'
    result = %x[khaleesi construction #{site_name} 2>&1]
    assert result.start_with?('A sample site of Khaleesi was built in')
    assert_equal Dir["#{site_name}/_decorators/*"].length, 2
    assert_equal Dir["#{site_name}/_pages/**/*"].length, 6
    assert_equal Dir["#{site_name}/_raw/**/*"].length, 3
    assert_equal Dir["#{site_name}/**/*"].length, 16
    %x[rm -fr #{site_name}]
  end

  def test_the_khaleesi_createpost_command
    post_name = 'mypost'
    result = %x[khaleesi createpost #{post_name} 2>&1]
    assert result.start_with?('A post page was created')

    post_name << '.md'
    page_content = IO.read(post_name)
    assert_match /^‡{6,}$/, page_content
    assert_match /^identifier:\p{Blank}?\p{Alnum}{20}$/, page_content
    %x[rm -fr #{post_name}]
  end

  def test_the_khaleesi_build_command
    dst_dir = File.absolute_path('resources/test_site/gen_site')
    src_dir = File.absolute_path('resources/test_site')

    result = %x[khaleesi build --src-dir #{src_dir} --dest-dir #{dst_dir} 2>&1]
    assert_match /^Done(.+)Generator time elapsed(.+)$/m, result
    
    # examine various foreach logical's correctness.
    assert_equal IO.read(dst_dir + '/index.html'), IO.read(src_dir + '/expected_index_html')

    # examine chain logical's correctness.
    assert_equal IO.read(dst_dir + '/themes/github.html'), IO.read(src_dir + '/expected_github_html') # only present next
    assert_equal IO.read(dst_dir + '/themes/base16_solarized.html'), IO.read(src_dir + '/expected_base16_solarized_html') # present next and previous
    assert_equal IO.read(dst_dir + '/themes/base16_solarized_dark.html'), IO.read(src_dir + '/expected_base16_solarized_dark_html')  # only present previous

    %x[rm -fr #{dst_dir}/*]
  end
end