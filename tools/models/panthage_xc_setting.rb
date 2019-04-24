#!/usr/bin/ruby

class XCodeTarget
  STATIC_LIB = 0
  DYNAMIC_LIB = STATIC_LIB + 1
  EXECUTABLE = DYNAMIC_LIB + 1

  attr_accessor :target_name,
                :product_name,
                :product_type,
                :mach_o_type,
                :type

  def initialize(target_name, product_name, type, product_type, mach_o_type)
    @target_name = target_name
    @product_name = product_name
    @product_type = product_type
    @mach_o_type = mach_o_type
    @type = type
  end

  def description
    "Target Name: #{target_name}, Product Name: #{product_name}, Type: #{type}, Product Type: #{product_type}, Mach-O Type: #{mach_o_type}"
  end

  def static?
    type == STATIC_LIB
  end

  def dylib?
    type == DYNAMIC_LIB
  end

  def exec?
    type == EXECUTABLE
  end
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