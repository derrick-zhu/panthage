#!/usr/bin/ruby
# frozen_string_literal: true

require 'test/unit'
require_relative '../tools/panthage_ver_helper'

class VersHelperTest < Test::Unit::TestCase
  attr_accessor :versions
  attr_accessor :versions_short

  def setup
    @versions = [
        '0.0.1', '0.1.0', '1.0.0',
        '0.1.1', '1.1.0', '1.1.1',
        '2.0.1', '2.1.2', '2.1.3', '2.1.4', '2.1.5', '2.1.6', '2.2.0', '2.2.1'
    ]

    @versions_short = [
        '0.0', '0.1', '1.0'
    ]

    @versions_prefix = %w[v0.0.1 v0.1.0 v1.0.0 v1.2.3 v2.0.1]
  end

  def test_find_version
    result = VersionHelper.find_fit_version(@versions, '2.1', '~>')
    assert(result.length == 1 && result.first == '2.2.1')

    result = VersionHelper.find_fit_version(@versions, '1.0', '~>')
    assert(result.length == 1 && result.first == '1.1.1')

    result = VersionHelper.find_fit_version(@versions_prefix, 'v1.0.0', '~>')
    assert(result.length == 1 && result.first == 'v1.2.3')
  end

  def test_ver_convert
    @versions.each do |ver|
      nver = VersionHelper.to_i(ver)
      sver = VersionHelper.to_s(nver)

      puts "testing #{ver}: want #{ver}, get #{sver}"
      assert(ver == sver)
    end
  end

  def test_ver_short_convert
    @versions_short.each do |ver|
      nver = VersionHelper.to_i(ver)
      sver = VersionHelper.to_ss(nver)

      puts "testing #{ver}: want #{ver}, get #{sver}"
      assert(ver == sver)
    end
  end
end
