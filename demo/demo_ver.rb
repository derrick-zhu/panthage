#!/usr/bin/ruby
# frozen_string_literal: true

ver = Gem::Version.new('3.1.2')
puts ver.to_s

vn = 0
Gem::Version.new('3.1.2').segments.each_with_index do |n, idx|
  puts "#{idx} -> #{n}"
  vn += (100**(2-idx) * n)
end
puts vn.to_s
