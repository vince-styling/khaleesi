require 'pathname'
require 'fileutils'

require 'redcarpet'
require 'pygments'
require 'rouge'
require 'time'

Dir[__dir__ + '/khaleesi/*.rb'].each do |file|
  require file
end