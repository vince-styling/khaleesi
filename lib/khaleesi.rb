require 'pathname'
require 'fileutils'

require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'time'

Dir[__dir__ + '/khaleesi/*.rb'].each do |file|
  require file
end