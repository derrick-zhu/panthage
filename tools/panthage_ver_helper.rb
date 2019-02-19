#!/usr/bin/ruby
# frozen_string_literal: true

# VersionHelper helper about version
class VersionHelper
  # to_i convert version to integer
  def self.to_i(ver)
    result = 0

    Gem::Version.new(ver).segments.each_with_index do |n, idx|
      result += (1000**(2 - idx) * n)
      raise 'unsupport version format' unless (idx < 4) && (n < 100)
    end

    result
  end

  def self.buildNo(ver)
    tmp = to_i(ver)
    tmp % (10**3)
  end

  def self.minorNo(ver)
    tmp = to_i(ver)
    (tmp % (10**6) * (0.1**3)).to_i
  end

  def self.majorNo(ver)
    tmp = to_i(ver)
    (tmp % (10**9) * (0.1**6)).to_i
  end
end
