module Khaleesi
  def self.version
    '0.0.1'
  end
  def self.author
    'vince styling'
  end
  def self.site
    'https://github.com/vince-styling/khaleesi'
  end
  def self.about
    puts 'Khaleesi is a site blog generator write by ruby.'
    puts "site : #{self.site}."
    puts "author : #{self.author}."
    puts "version : #{self.version}."
  end
end
