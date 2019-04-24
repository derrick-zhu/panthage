#!/usr/bin/ruby

require 'test/unit'
require_relative '../tools/panthage_xcode_project'

class TestXcodeProject < Test::Unit::TestCase
  attr_reader :xcode_proj_path,
              :xcode_proj

  def setup
    @xcode_proj_path = './sample/Kingfisher.xcodeproj' #'./sample/OHHTTPStubs.xcodeproj'
    @xcode_proj = XcodeProject.new(@xcode_proj_path, 'Debug', XcodePlatformSDK::IPHONE)
    # puts @xcode_proj.description
  end

  def teardown
    # Do nothing
  end

  def test_load_xcode_proj
    assert(!xcode_proj.nil?)
  end

  def test_mach_type
    assert(xcode_proj.product_exec?)
  end

  def test_xc_proj_description
    xcode_proj.targets.each do |each_xc|
      puts each_xc.description
    end
    assert(true)
  end

  def test_xc_proj_schemes
    xcode_proj.schemes.each do |each_scheme|
      puts each_scheme.to_s
    end
    assert(true)
  end

  def test_sdk_identifier
    assert(XcodePlatformSDK.to_s(XcodePlatformSDK::IPHONE) == 'iOS')
    assert(XcodePlatformSDK.to_s(XcodePlatformSDK::MACOS) == 'macOS')
    assert(XcodePlatformSDK.to_s(XcodePlatformSDK::TVOS) == 'tvOS')
    assert(XcodePlatformSDK.to_s(XcodePlatformSDK::WATCHOS) == 'watchOS')
  end
end