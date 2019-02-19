#!/usr/bin/ruby
# frozen_string_literal: true

def version_to_int(ver)
  result = 0

  Gem::Version.new(ver).segments.each_with_index do |n, idx|
    result += (1000**(2 - idx) * n)
    raise 'unsupport version format' unless (idx < 4) && (n < 100)
  end

  result
end

def self.version_build(ver)
  tmp = version_to_int(ver)
  tmp % (10**3)
end

def self.version_minor(ver)
  tmp = version_to_int(ver)
  (tmp % (10**6) * (0.1**3)).to_i
end

def self.version_major(ver)
  tmp = version_to_int(ver)
  (tmp % (10**9) * (0.1**6)).to_i
end

ver_str = '3.1.2'

puts version_to_int(ver_str).to_s
puts version_major(ver_str)
puts version_minor(ver_str)
puts version_build(ver_str)
