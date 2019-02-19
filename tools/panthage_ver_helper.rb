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

  def self.build_no(ver)
    tmp = to_i(ver)
    tmp % (10**3)
  end

  def self.minor_no(ver)
    tmp = to_i(ver)
    (tmp % (10**6) * (0.1**3)).to_i
  end

  def self.major_no(ver)
    tmp = to_i(ver)
    (tmp % (10**9) * (0.1**6)).to_i
  end

  def self.int_to_version(nver)
    major = (nver % (10**9) * (0.1**6)).to_i
    minor = (nver % (10**6) * (0.1**3)).to_i
    build = (nver % (10**3)).to_i
    "#{major}.#{minor}.#{build}"
  end

  def self.find_fit_version(versions, base_ver) 
    ivers = versions.collection { |ver| version_to_int(ver) }
    bver = version_to_int(base_ver)
    end
  end
end
