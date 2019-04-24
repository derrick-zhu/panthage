#!/usr/bin/ruby
#

require 'xcodeproj'
require_relative 'utils/panthage_xml'
require_relative 'models/panthage_xc_setting'
require_relative 'models/panthage_xc_scheme_model'

module XcodeProjectBuildSettings
  MACH_O_TYPE = "MACH_O_TYPE"
  PRODUCT_NAME = "PRODUCT_NAME"
end

module XcodeProjectMachOType
  DYNAMIC_LIB = "mh_dylib"
  EXECUTE = "mh_execute"
  STATIC_LIB = "staticlib"
end

module XcodeProjectProductType
  APPLICATION = "com.apple.product-type.application"
  STATIC_LIB = "com.apple.product-type.library.static"
  DYNAMIC_LIB = "com.apple.product-type.framework"
  UI_TESTING = "com.apple.product-type.bundle.ui-testing"
  UNIT_TESTING = "com.apple.product-type.bundle.unit-test"
  APP_EXTENSION_MESSAGES = "com.apple.product-type.app-extension.messages"
  APP_EXTENSION = "com.apple.product-type.app-extension"
end

module XcodePlatformSDK
  IPHONE = "iphoneos"
  MACOS = "macosx"
  TVOS = "appletvos"
  WATCHOS = "watchos"

  def self.to_s(sdk)
    case sdk
    when IPHONE
      'iOS'
    when MACOS
      'macOS'
    when TVOS
      'tvOS'
    when WATCHOS
      'watchOS'
    else
      'unknown'
    end
  end
end

class XcodeProject
  attr_reader :xcode_project,
              :project,
              :platform,
              :configuration,
              :target_name

  def initialize(xcode_proj_path, configure, platform)
    @xcode_project = xcode_proj_path
    @project = Xcodeproj::Project.open(xcode_proj_path.to_s)
    @platform = !(platform.nil? || platform.empty?) ? platform : XcodePlatformSDK::iOS
    @target_name = ""
    @configuration = (!(configure.nil? || configure.empty?)) ? configure : XcodeBuildConfigure::DEBUG
  end

  def description
    project.pretty_print
  end

  def targets
    result = []
    project.targets.select do |each_target|
      if static?(each_target.name)
        result.append(XCodeTarget.new(each_target.name,
                                      product_name(each_target.name),
                                      XCodeTarget::STATIC_LIB,
                                      each_target.product_type,
                                      mach_o_type(each_target.name))
        )
      elsif dylib?(each_target.name)
        result.append(XCodeTarget.new(each_target.name,
                                      product_name(each_target.name),
                                      XCodeTarget::DYNAMIC_LIB,
                                      each_target.product_type,
                                      mach_o_type(each_target.name))
        )
      elsif executable?(each_target.name)
        result.append(XCodeTarget.new(each_target.name,
                                      product_name(each_target.name),
                                      XCodeTarget::EXECUTABLE,
                                      each_target.product_type,
                                      mach_o_type(each_target.name))
        )
      end
    end

    result
  end

  def schemes
    result = []
    Xcodeproj::Project.schemes(xcode_project).each do |each_scheme|
      scheme_file = "#{File.absolute_path(xcode_project)}/xcshareddata/xcschemes/#{each_scheme}.xcscheme"
      next unless File.exist?(scheme_file)

      scheme_json = XMLUtils.to_json(File.read(scheme_file))["Scheme"]
      next unless !scheme_json.nil?

      scheme_obj = XcodeSchemeModel.new(scheme_json["LastUpgradeVersion"], scheme_json["version"], scheme_json["BuildAction"], scheme_json["TestAction"])

      result.append(XCodeSchemeConfig.new(each_scheme.to_s,
                                          scheme_obj.BuildAction.BuildActionEntries.BuildableReference.BlueprintName,
                                          scheme_obj.BuildAction.BuildActionEntries.BuildableReference.ReferencedContainer))
    end

    result
  end

  def scheme_for_target(target_name)
    self.schemes.select { |each_scheme| each_scheme.target_name == target_name }.first
  end

  def product_name(target_name, configure = @configuration)
    name = build_setting_for(target_name, configure, XcodeProjectBuildSettings::PRODUCT_NAME)
    meta = %r{^\$\(TARGET_NAME([:][\w]*)?\)$}.match(name)

    !meta.nil? ? target_name : name
  end

  def mach_o_type(target_name = @target_name, configure = @configuration)
    raise "fatal: target name is needed." if target_name.nil? || target_name.empty?

    build_setting_for(target_name, configure, XcodeProjectBuildSettings::MACH_O_TYPE)
  end

  def static?(target_name = @target_name)
    raise "fatal: target name is needed." if target_name.nil? || target_name.empty?

    XcodeProjectProductType::STATIC_LIB == product_type(target_name)
  end

  def dylib?(target_name = @target_name)
    raise "fatal: target name is needed." if target_name.nil? || target_name.empty?

    XcodeProjectProductType::DYNAMIC_LIB == product_type(target_name)
  end

  def executable?(target_name = @target_name)
    raise "fatal: target name is needed." if target_name.nil? || target_name.empty?

    XcodeProjectProductType::APPLICATION == product_type(target_name)
  end

  def save
    project.save
  end

  def add_link_framework(target_scheme, framework_path)
    raise "fatal: target name is needed." if target_name.nil? || target_name.empty?

    found_scheme_target = target_with(target_scheme)
    raise "fatal: could not find target '#{target_scheme}'" if found_scheme_target.nil?

    framework_ref = project.frameworks_group.new_file(framework_path)
    found_scheme_target.frameworks_build_phases.add_file_reference(framework_ref)
  end

  private

  def mach_o_static?(target_name = @target_name)
    mach_o_type(target_name) == XcodeProjectMachOType::STATIC_LIB
  end

  def mach_o_dylib?(target_name = @target_name)
    mach_o_type(target_name) == XcodeProjectMachOType::DYNAMIC_LIB
  end

  def mach_o_exec?(target_name = @target_name)
    mach_o_type(target_name) == XcodeProjectMachOType::EXECUTE
  end

  def product_static?(target_name = @target_name)
    product_type(target_name) == XcodeProjectProductType::STATIC_LIB
  end

  def product_dylib?(target_name = @target_name)
    product_type(target_name) == XcodeProjectProductType::DYNAMIC_LIB
  end

  def product_exec?(target_name = @target_name)
    product_type(target_name) == XcodeProjectProductType::APPLICATION
  end

  def target_with(target_name)
    raise "fatal: invalid XcodeProj instance for #{xcode_project}" if project.nil?

    project.targets.each_with_index do |each_target, idx|
      if each_target.name == target_name || target_name == product_name(each_target.name)
        return project.targets[idx]
      end
    end
  end

  def build_settings_for(target_name, configuration)
    target = target_with(target_name)
    configs = target.build_configurations.select {|each_config| each_config.name == configuration}
    configs.first.build_settings unless configs.empty?
  end

  def product_type(target_name)
    target_with(target_name).product_type
  end

  def build_setting_for(target_name, configure, setting)
    build_settings = build_settings_for(target_name, configure)
    build_settings[setting] if !build_settings.nil? && build_settings.has_key?(setting)
  end
end
