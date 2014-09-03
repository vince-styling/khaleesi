require 'pathname'
require 'fileutils'

require 'redcarpet'
require 'pygments'
require 'rouge'
require 'time'
require 'cgi'

Dir[__dir__ + '/khaleesi/*.rb'].each do |file|
  require file
end