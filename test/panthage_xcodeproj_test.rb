#!/usr/bin/ruby

require 'test/unit'

require_relative '../tools/xcode_proj/models/panthage_xc_scheme_model'
require_relative '../tools/xcode_proj/panthage_xcode_project'
require_relative '../tools/xcode_proj/panthage_xcode_project_utils'

class TestXcodeProject < Test::Unit::TestCase
  attr_reader :xcode_proj_path,
              :xcode_proj

  def setup
    @xcode_proj_path = './sample/Kingfisher.xcodeproj' #'./sample/OHHTTPStubs.xcodeproj'
    @xcode_proj = XcodeProject.new(@xcode_proj_path, 'Debug', XcodePlatformSDK::FOR_IOS)
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

  def test_xc_proj_scheme_find
    @xcode_proj_path = './sample/Kingfisher.xcodeproj' #'./sample/OHHTTPStubs.xcodeproj'
    @xcode_proj = XcodeProject.new(@xcode_proj_path, 'Debug', XcodePlatformSDK::FOR_IOS)

    scheme = xcode_proj.scheme_for_target('Kingfisher-iOS')
    assert(!scheme.nil?)
    scheme = xcode_proj.scheme_for_target('Kingfisher')
    assert(scheme.nil? || scheme.empty?)

    self.setup
  end

  def test_sdk_identifier
    assert(XcodePlatformSDK.to_s(XcodePlatformSDK::FOR_IOS) == 'iOS')
    assert(XcodePlatformSDK.to_s(XcodePlatformSDK::FOR_MACOS) == 'macOS')
    assert(XcodePlatformSDK.to_s(XcodePlatformSDK::FOR_TVOS) == 'tvOS')
    assert(XcodePlatformSDK.to_s(XcodePlatformSDK::FOR_WATCHOS) == 'watchOS')
  end

  def test_xc_proj_references
    xcode_proj_path = './sample/Panda.xcodeproj' #'./sample/OHHTTPStubs.xcodeproj'
    xcode_proj = XcodeProject.new(xcode_proj_path, 'Debug', XcodePlatformSDK::FOR_IOS)

    # xcode_proj.project.root_object.main_group.groups.each { |each_group| puts each_group.to_s }
    puts xcode_proj.project.objects_by_uuid.each { |uuid| puts uuid.to_json }
    xcode_proj.project.root_object.project_references.each do |each_ref|
      puts each_ref.to_s
      puts each_ref[:product_group].uuid.to_s

      xcode_proj.project.objects_by_uuid[each_ref[:product_group].uuid].children.each do |each_child|
        puts each_child.path
      end
    end
    # xcode_proj.project.root_object.project_references.each do |each_references|
    #   puts each_references[:product_group].uuid.to_s
    # end

    self.setup
  end

  def test_xc_project_has_swift
    # test swift project
    xcode_proj_path = './sample/panthage_foo/panthage_foo.xcodeproj'
    xcode_proj = XcodeProject.new(xcode_proj_path, 'Debug', XcodePlatformSDK::FOR_IOS)

    assert(xcode_proj.is_swift_project? 'panthage_foo')

    # test objective-c project
    xcode_proj_path = './sample/panthage_foo_objc/panthage_foo_objc.xcodeproj'
    xcode_proj = XcodeProject.new(xcode_proj_path, 'Debug', XcodePlatformSDK::FOR_IOS)

    assert(!xcode_proj.is_swift_project?('panthage_foo_objc'))
  end
end