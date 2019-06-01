#!/usr/bin/ruby

require_relative 'panthage_xcode_sdk'

module XcodePlatformSDK
  FOR_UNKNOWN = 0
  FOR_IOS = FOR_UNKNOWN + 1
  FOR_MACOS = FOR_IOS + 1
  FOR_WATCHOS = FOR_MACOS + 1
  FOR_TVOS = FOR_WATCHOS + 1

  def self.to_s(sdk)
    case sdk
    when FOR_IOS
      'iOS'
    when FOR_MACOS
      'macOS'
    when FOR_TVOS
      'tvOS'
    when FOR_WATCHOS
      'watchOS'
    else
      'unknown'
    end
  end

  def self.nil?
    self == FOR_UNKNOWN
  end

  def self.empty?
    self == FOR_UNKNOWN
  end
end

class XCodeTarget
  include XcodeSDKRoot

  STATIC_LIB = 0
  DYNAMIC_LIB = STATIC_LIB + 1
  EXECUTABLE = DYNAMIC_LIB + 1

  attr_reader :sdk_root,
              :target_name,
              :product_name,
              :product_type,
              :mach_o_type,
              :bin_type,
              :platform_type

  def initialize(sdk_root, target_name, product_name, bin_type, product_type, mach_o_type)
    @sdk_root = sdk_root
    @target_name = target_name
    @product_name = product_name
    @product_type = product_type
    @mach_o_type = mach_o_type
    @bin_type = bin_type
    @platform_type = XcodeSDKRoot.type_of(@sdk_root)
  end

  def description
    "Target Name: #{target_name}, SDK: #{sdk_root}, Product Name: #{product_name}, Type: #{bin_type}, Product Type: #{product_type}, Mach-O Type: #{mach_o_type}"
  end

  def static?
    bin_type == STATIC_LIB
  end

  def dylib?
    bin_type == DYNAMIC_LIB
  end

  def exec?
    bin_type == EXECUTABLE
  end

  def mach_o_static?
    @mach_o_type == XcodeProjectMachOType::STATIC_LIB
  end

  def mach_o_dylib?
    @mach_o_type == XcodeProjectMachOType::DYNAMIC_LIB
  end

  def mach_o_exec?
    @mach_o_type == XcodeProjectMachOType::EXECUTE
  end
end

class XCodeSchemeConfig
  attr_reader :name, :target_name, :app_name

  def initialize(name, target_name, app_name)
    @name = name
    @target_name = target_name
    @app_name = app_name
  end

  def app_product_name
    "" if app_name&.empty?

    dot_idx = app_name.index(".")
    app_name if dot_idx.nil?

    app_name[0, dot_idx]
  end
end