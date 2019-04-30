#!/usr/bin/ruby

class XCodeTarget
  FOR_IOS = 0
  FOR_MACOS = FOR_IOS + 1
  FOR_WATCHOS = FOR_MACOS + 1
  FOR_TVOS = FOR_WATCHOS + 1

  STATIC_LIB = 0
  DYNAMIC_LIB = STATIC_LIB + 1
  EXECUTABLE = DYNAMIC_LIB + 1

  attr_accessor :sdk_root,
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
end

def iOS?
  @platform_type == FOR_IOS
end

def macOS?
  @platform_type == FOR_MACOS
end

def watchOS?
  @platform_type == FOR_WATCHOS
end

def tvOS?
  @platform_type == FOR_TVOS
end

class XCodeSchemeConfig
  attr_reader :name, :target_name, :ref_container
  def initialize(name, target_name, ref_container)
    @name = name
    @target_name = target_name
    @ref_container = ref_container
  end

  def match_target(t_name)
    target_name == t_name
  end
end