require 'redcarpet'
require 'nokogiri'
require 'rouge'

module Khaleesi
  class << self
    def markdown(text)
      options = [:fenced_code, :autolink, :no_intraemphasis, :generate_toc, :strikethrough, :gh_blockcode, :xhtml, :tables]
      syntax_highlighter(Redcarpet.new(text, *options).to_html)
    end

    def syntax_highlighter(html)
      doc = Nokogiri::HTML(html)

      doc.search('//pre[@lang]').each do |pre|
        pre.replace rouge_colorize(pre.text.rstrip, pre[:lang])
      end

      # avaliable fields like .inner_html at http://nokogiri.org/Nokogiri/XML/Node.html
      # fetch the body elements.
      doc.at('body').inner_html

      # output all document as text.
      # doc.to_s
    end

    def rouge_colorize(source, lang)
      # find the correct lexer class by given name.
      # avaliable language : http://rubydoc.info/gems/rouge/Rouge/Lexers
      lexer_class = Rouge::Lexer.find(lang)
      if lexer_class == nil
        warn "WARNING : lexer_class[#{lang}] not match.\n"
        # puts Rouge::Lexer.find_fancy('guess', source)
        lexer_class = Rouge::Lexers::PlainText
      end

      #formatter = Rouge::Formatters::HTML.new(css_class: 'highlight', line_numbers: true)
      formatter = Rouge::Formatters::HTML.new(css_class: 'highlight')
      formatter.format(lexer_class.new.lex(source))
    end
  end
end

def test_parse_single_file
  file = File.read('/Users/vince/dev/git_marked/README.md')
  Khaleesi.markdown(file)
end

# puts test_parse_single_file
# puts Khaleesi::version