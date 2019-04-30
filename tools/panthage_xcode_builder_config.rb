#!/usr/bin/ruby
# frozen_string_literal: true

require 'json'
require_relative 'panthage_xcode_builder_config.rb'

module XcodeSDKRoot
  SDK_IPHONEOS = 'iphoneos'
  SDK_IPHONE_SIMULATOR = 'iphonesimulator'
  SDK_TVOS = 'appletvos'
  SDK_MACOSX = 'macosx'
  SDK_WATCHOS = 'watchos'

  def self.type_of(sdk_root)
    case sdk_root
    when SDK_IPHONEOS, SDK_IPHONE_SIMULATOR
      XCodeTarget::FOR_IOS
    when SDK_TVOS
      XCodeTarget::FOR_TVOS
    when SDK_MACOSX
      XCodeTarget::FOR_MACOS
    when SDK_WATCHOS
      XCodeTarget::FOR_WATCHOS
    end
  end

  def self.sdk_root(sdk_type)
    case sdk_type
    when XCodeTarget::FOR_IOS
      [SDK_IPHONEOS, SDK_IPHONE_SIMULATOR]
    when XCodeTarget::FOR_MACOS
      [SDK_MACOSX]
    when XCodeTarget::FOR_TVOS
      [SDK_TVOS]
    when XCodeTarget::FOR_WATCHOS
      [SDK_WATCHOS]
    else
      []
    end
  end
end

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
              :platform_sdk

  attr_accessor :quiet_mode, :sdk, :simulator_mode, :framework_version_hash

  def initialize(work_dir, xcode_project, scheme, config, derived_path, dwarf_dSYM_path, dwarf_type, build_output, platform_sdk)
    @work_dir = work_dir
    @project = xcode_project
    @scheme = scheme
    @configuration = config
    @sdk = ''
    @derived_path = derived_path
    @dwarf_dSYM_path = dwarf_dSYM_path
    @dwarf_type = dwarf_type
    @build_output = build_output
    @platform_sdk = platform_sdk
  end

  def sdk=(new_sdk)
    @sdk = new_sdk
    if @sdk == XcodeSDKRoot::SDK_IPHONEOS || @sdk == XcodeSDKRoot::SDK_IPHONE_SIMULATOR
      @simulator_mode = @sdk == XcodeSDKRoot::SDK_IPHONEOS ? false : @sdk == XcodeSDKRoot::SDK_IPHONE_SIMULATOR
    else
      @simulator_mode = false
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

  def to_xc
    raise "fatal: invalid sdk #{@sdk}" if sdk.empty?

    {
        "-project": @project,
        "-scheme": @scheme,
        "-configuration": @configuration,
        "-sdk": @sdk,
        "-derivedDataPath": @derived_path
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

  def arches
    if iOSSimulator?
      %w[-arch x86_64 -arch i386].join(' ')
    elsif iOS?
      %w[-arch arm64 -arch armv7 -arch armv7s].join(' ')
    else
      ''
    end
  end

  def valid_archs
    if iOSSimulator?
      {"VALID_ARCHS": "'i386 x86_64'"}
    elsif iOS?
      {"VALID_ARCHS": "'arm64 arm64e armv7 armv7s'"}
    else
      {}
    end
  end
end
