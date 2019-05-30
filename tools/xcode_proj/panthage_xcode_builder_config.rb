#!/usr/bin/ruby
# frozen_string_literal: true

require 'json'

# XcodeBuilder
class XcodeBuildConfigure
  DEBUG = 'Debug'
  RELEASE = 'Release'

  attr_reader :work_dir,
              :project,
              :scheme,
              :configuration,
              :derived_path,
              :dwarf_dSYM_path,
              :dwarf_type,
              :build_output,
              :platform_sdk,
              :is_swift_project

  attr_accessor :quiet_mode, :sdk, :simulator_mode, :framework_version_hash

  def initialize(work_dir, xcode_project, scheme, config, derived_path, dwarf_dSYM_path, build_output, platform_sdk, is_swift_project)
    @work_dir = work_dir
    @project = xcode_project
    @scheme = scheme
    @configuration = config
    @sdk = ''
    @derived_path = derived_path
    @dwarf_dSYM_path = dwarf_dSYM_path
    @dwarf_type = 'dwarf-with-dsym'
    @build_output = build_output
    @platform_sdk = platform_sdk
    @is_swift_project = is_swift_project
  end

  def sdk=(new_sdk)
    @sdk = new_sdk
    if @sdk == XcodeSDKRoot::SDK_IPHONEOS || @sdk == XcodeSDKRoot::SDK_IPHONE_SIMULATOR
      @simulator_mode = @sdk == XcodeSDKRoot::SDK_IPHONEOS ? false : @sdk == XcodeSDKRoot::SDK_IPHONE_SIMULATOR
    else
      @simulator_mode = false
    end
  end

  def to_xc
    raise "fatal: invalid sdk #{@sdk}" if sdk.empty?

    {
        "-project": "'#{@project}'",
        "-scheme": "'#{@scheme}'",
        "-configuration": "'#{@configuration}'",
        "-sdk": "'#{@sdk}'",
        "-derivedDataPath": "'#{@derived_path}'"
    }.to_xc_s(' ') + ' ' + arches
  end

  def to_xc_param
    {
        "only_active_arch": 'no',
        "defines_module": 'yes',
        "DWARF_DSYM_FOLDER_PATH": "'#{@dwarf_dSYM_path}'",
        "DEBUG_INFORMATION_FORMAT": "'#{@dwarf_type}'",
        "CONFIGURATION_BUILD_DIR": "'#{@build_output}/#{@configuration}_#{@sdk}'"
    }.merge(valid_archs).to_xc_s('=')
  end

  def to_xc_ext_param
    result = []
    result.push('clean build')
    result.push('-quiet') if quiet_mode

    result.join(' ').strip.freeze
  end

  private

=begin
* 如果全部支持切不在乎包大小的话,Architecture的值选择：armv7 armv7s arm64
* 如果支持5以上切包不要求则选用 armv7s ,arm64
* 如果支持全机型,有不想ipa包太多就选择 armv7 , arm64\
* 如果最小ipa的话,切抛弃5s以下,可以采用只用arm64
---------------------
ref：https://blog.csdn.net/qq_24702189/article/details/79345387
=end
  def arches
    if iOSSimulator?
      %w[-arch x86_64 -arch i386].join(' ')
    elsif iOS?
      %w[-arch arm64 -arch armv7].join(' ')
    else
      ''
    end
  end

  def valid_archs
    if iOSSimulator?
      {"VALID_ARCHS": "'i386 x86_64'"}
    elsif iOS?
      {"VALID_ARCHS": "'armv7 armv7s arm64 arm64e'"}
    else
      {}
    end
  end

  def iOS?
    @sdk == XcodeSDKRoot::SDK_IPHONEOS
  end

  def iOSSimulator?
    @sdk == XcodeSDKRoot::SDK_IPHONE_SIMULATOR
  end

  def tvOS?
    @sdk == XcodeSDKRoot::SDK_TVOS
  end

  def watchOS?
    @sdk == XcodeSDKRoot::SDK_WATCHOS
  end

  def macOS?
    @sdk == XcodeSDKRoot::SDK_MACOSX
  end
end
