module Khaleesi
  def self.version
    '0.1.0'
  end
  def self.author
    'vince styling'
  end
  def self.date
    '2014-09-17'
  end
  def self.site
    'http://khaleesi.vincestyling.com/'
  end
  def self.summary
    'Khaleesi is a static site generator write in Ruby.'
  end
  def self.about
    puts self.summary
    puts "site : #{self.site}."
    puts "author : #{self.author}."
    puts "version : #{self.version}."
  end
end
