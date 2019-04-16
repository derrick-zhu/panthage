#!/usr/bin/ruby
# frozen_string_literal: true

require 'json'
require_relative 'panthage_xcode_config.rb'

# XcodeBuilder
class XcodeProjectConfigure
  attr_reader :project,
              :scheme,
              :configuration,
              :sdk,
              :derived_path,
              :dwarf_dSYM_path,
              :dwarf_type,
              :build_output

  def initialize(project, scheme, config, sdk, derived_path, dwarf_dSYM_path, dwarf_type, build_output)
    @project = project
    @scheme = scheme
    @configuration = config
    @sdk = sdk
    @derived_path = derived_path
    @dwarf_dSYM_path = dwarf_dSYM_path
    @dwarf_type = dwarf_type
    @build_output = build_output
  end

  def to_xc
    {
      "-project": @project,
      "-scheme": @scheme,
      "-configuration": @configuration,
      "-sdk": @sdk
    }.to_xc_s(' ')
  end

  def to_xc_param
    {
      "DWARF_DSYM_FOLDER_PATH": "\'#{@dwarf_dSYM_path}\'",
      "DEBUG_INFORMATION_FORMAT": "\'#{@dwarf_type}\'",
      "CONFIGURATION_BUILD_DIR": "\'#{@build_output}\'"
    }.to_xc_s('=')
  end
end
