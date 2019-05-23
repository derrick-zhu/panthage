#!/usr/bin/ruby
# frozen_string_literal: true

require_relative 'panthage_dependency'

# VersionHelper helper about version
class VersionHelper
  FIX_METHOD = [
      EQUAL = '==',
      HIGHER = '>',
      HIGHER_EQUAL = '>=',
      HIGHER_COMPATIBLE = '~>'
  ].freeze

  # to_i convert version to integer
  def self.to_i(ver)
    result = 0

    begin
      Gem::Version.new(ver).segments.each_with_index do |n, idx|
        result += (1000 ** (2 - idx) * n)
        raise 'unsupport version format' unless (idx < 4) && (n < 100)
      end
    rescue StandardError => exception
      result = -1
      puts exception.to_s if PanConstants.debugging
    end

    result
  end

  def self.build_no(ver)
    tmp = to_i(ver)
    tmp % (10 ** 3)
  end

  def self.minor_no(ver)
    tmp = to_i(ver)
    (tmp % (10 ** 6) * (0.1 ** 3)).to_i
  end

  def self.major_no(ver)
    tmp = to_i(ver)
    (tmp % (10 ** 9) * (0.1 ** 6)).to_i
  end

  def self.to_s(nver)
    major = (nver % (10 ** 9) * (0.1 ** 6)).to_i
    minor = (nver % (10 ** 6) * (0.1 ** 3)).to_i
    build = (nver % (10 ** 3)).to_i
    "#{major}.#{minor}.#{build}"
  end

  def self.to_ss(nver)
    major = (nver % (10 ** 9) * (0.1 ** 6)).to_i
    minor = (nver % (10 ** 6) * (0.1 ** 3)).to_i
    build = (nver % (10 ** 3)).to_i

    build.zero? ? "#{major}.#{minor}" : "#{major}.#{minor}.#{build}"
  end

  def self.identify(ver)
    nver = VersionHelper.to_i(ver)
    VersionHelper.to_s(nver)
  end

  def self.find_fit_version(versions, base_ver, compare_method)
    prefix = ver_prefix(base_ver)
    base_ver = pure_ver(base_ver)

    tmp_vers = []
    versions.each {|each_version| tmp_vers.push(pure_ver(each_version))}
    versions = tmp_vers

    ivers = versions.collect! {|ver| VersionHelper.to_i(ver)}.select {|ver| ver >= 0}
    bver = VersionHelper.to_i(base_ver)
    bver = bver >= 0 ? bver : 0

    tmps = []

    case compare_method
    when EQUAL
      tmps = ivers.select {|ver| ver == bver}
    when HIGHER
      tmps = ivers.select {|ver| ver > bver}
    when HIGHER_EQUAL
      tmps = ivers.select {|ver| ver >= bver}
    when HIGHER_COMPATIBLE
      tmps = ivers.select {|ver| !(ver - bver).negative? && (ver - bver) < (10 ** 6)}
    end

    tmps = tmps.sort! {|a, b| b <=> a}
    tmps.length.positive? ? ["#{prefix}#{VersionHelper.to_s(tmps.first)}"] : []
  end

  private_class_method def self.ver_prefix(ver)
                         ver_reg = %r{([a-zA-Z]*)?([\d]+).?}

                         meta = ver.scan ver_reg
                         '' if meta.nil? || meta.size == 0

                         meta[0][0] ? meta[0][0] : ''
                       end

  private_class_method def self.pure_ver(ver)
                         ver_reg = %r{([a-zA-Z]*)?([\d]+).?}

                         meta = ver.scan ver_reg
                         '' if meta.nil? || meta.size == 0

                         list = []
                         meta&.each_with_index {|v, _| list.push v[1]}
                         list.join '.'
                       end
end
