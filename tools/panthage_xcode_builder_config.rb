#!/usr/bin/ruby
# frozen_string_literal: true

require 'json'
require_relative 'panthage_xcode_builder_config.rb'

# XcodeBuilder
class XcodeBuildConfigure
  IPHONEOS = 'iphoneos'
  IPHONE_SIMULATOR = 'iphonesimulator'

  CONFIG_DEBUG = 'Debug'
  CONFIG_RELEASE = 'Release'

  attr_reader :work_dir,
              :project,
              :scheme,
              :configuration,
              :derived_path,
              :dwarf_dSYM_path,
              :dwarf_type,
              :build_output

  attr_accessor :quiet_mode, :sdk, :simulator_mode, :framework_version_hash

  def initialize(work_dir, xcode_project, scheme, config, derived_path, dwarf_dSYM_path, dwarf_type, build_output)
    @work_dir = work_dir
    @project = xcode_project
    @scheme = scheme
    @configuration = config
    @sdk = ''
    @derived_path = derived_path
    @dwarf_dSYM_path = dwarf_dSYM_path
    @dwarf_type = dwarf_type
    @build_output = build_output
  end

  def sdk=(new_sdk)
    @sdk = new_sdk
    @simulator_mode = @sdk == IPHONEOS ? false : @sdk == IPHONE_SIMULATOR
  end

  def to_xc
    raise "fatal: invalid sdk #{@sdk}" if sdk.empty?

    {
      "-project": @project,
      "-scheme": @scheme,
      "-configuration": @configuration,
      "-sdk": @sdk,
      "-derivedDataPath": @derived_path
    }.to_xc_s(' ') + ' ' + arches(simulator_mode)
  end

  def to_xc_param
    {
      "only_active_arch": 'no',
      "defines_module": 'yes',
      "DWARF_DSYM_FOLDER_PATH": "'#{@dwarf_dSYM_path}'",
      "DEBUG_INFORMATION_FORMAT": "'#{@dwarf_type}'",
      "CONFIGURATION_BUILD_DIR": "'#{@build_output}/#{@configuration}_#{@sdk}'"
    }.merge(valid_archs(@simulator_mode)).to_xc_s('=')
  end

  def to_xc_ext_param
    result = []
    result.push('clean build')
    result.push('-quiet') if quiet_mode

    result.join(' ').strip.freeze
  end

  private

  def arches(is_simulator)
    if is_simulator
      %w[-arch x86_64 -arch i386].join(' ')
    else
      %w[-arch arm64 -arch arm64e -arch armv7 -arch armv7s].join(' ')
    end
  end

  def valid_archs(is_simulator)
    if is_simulator
      {
        "VALID_ARCHS": "'i386 x86_64'"
      }
    else
      {
        "VALID_ARCHS": "'arm64 arm64e armv7 armv7s'"
      }
    end
  end
end
