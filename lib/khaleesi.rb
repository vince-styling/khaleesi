require 'pathname'

require 'redcarpet'
require 'nokogiri'
require 'rouge'

Dir[__dir__ + '/khaleesi/*.rb'].each do |file|
  require file
end