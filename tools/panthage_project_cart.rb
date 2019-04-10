#!/usr/bin/ruby
# frozen_string_literal: true

require 'singleton'
require_relative 'string_ext'
require_relative 'panthage_ver_helper'
require_relative 'panthage_cartfile_model'

# FrameworkBuildTable
class FrameworkBuildInfo
  attr_reader :name, :framework
  attr_accessor :is_ready

  def initialize(name, framework)
    @name = name
    @is_ready = false
    @framework = framework
  end

  def need_build
    false if framework.nil?
    true if framework.dependency.empty?

    result = true
    framework.dependency.each do |scheme, _|
      result &&= ProjectCartManager.instance.is_framework_ready?(scheme)
      break unless result
    end

    result
  end

  def description
    "FrameBuildInfo:#{name}, is_ready:#{is_ready}, framework info:#{framework.description}"
  end
end

# ProjectCartManager
class ProjectCartManager
  include Singleton

  attr_reader :frameworks

  def initialize
    @frameworks = {}
  end

  def description
    result = ''

    frameworks.each do |_, each_lib|
      result += each_lib.description + "\n"
    end

    result
  end

  def append_framework(new_lib)
    raise "invalid library \'#{new_lib}\'" if new_lib.nil?

    old_lib = framework_with_name(new_lib.proj_name)

    unless old_lib.nil?
      verify_library_compatible(new_lib, old_lib)
      puts "#{new_lib.proj_name} had been there.\nNewLib: #{new_lib.description}\nOldLib: #{old_lib.description}"
    end

    puts new_lib.description.bg_gray.red.to_s

    case new_lib.conflict_type
    when ConflictType::ERROR
      raise "Halt !!! #{new_lib.error_msg}"
    when ConflictType::ACCEPT
      puts new_lib.error_msg.to_s
      frameworks[new_lib.proj_name] = FrameworkBuildInfo.new(new_lib.proj_name, new_lib)
    end

    new_lib.conflict_type == ConflictType::ACCEPT
  end

  def framework_with_name(name)
    frameworks[name].framework if frameworks.key?(name)
  end

  def build_info_with_name(name)
    frameworks[name] if frameworks.key?(name)
  end

  def is_framework_ready?(name)
    false if frameworks.nil? || frameworks.empty?
    false unless frameworks.key?(name)

    build_info_with_name(name).is_ready
  end

  # fetch any binary framework needs to be download.
  def any_binary_framework
    tmp = frameworks.select { |_, value| value.is_ready == false && value.framework.lib_type == LibType::BINARY }
    tmp.values[0] unless tmp.empty?
  end

  def any_repo_framework
    tmp = frameworks.select { |_, value| value.is_ready == false && value.need_build }
    tmp.values[0] unless tmp.empty?
  end

  private

  def verify_library_compatible(new_lib, old_lib)
    raise "could not verfiy library compatible between \'#{new_lib.proj_name}\' and \'#{old_lib.proj_name}\'" if new_lib.proj_name != old_lib.proj_name
    raise "incompatible library type: \n\t\'#{new_lib.proj_name}\'(#{new_lib.belong_proj_name}) -> #{new_lib.lib_type}\n and \n\t\'#{old_lib.proj_name}\'(#{old_lib.belong_proj_name}) -> #{new_lib.lib_type}" if new_lib.lib_type != old_lib.lib_type
    raise "incompatible library repo type: \n\t\'#{new_lib.proj_name}\'(#{new_lib.belong_proj_name}) -> #{new_lib.repo_type}\n and \n\t\'#{old_lib.proj_name}\'(#{old_lib.belong_proj_name}) -> #{new_lib.repo_type}" if new_lib.repo_type != old_lib.repo_type

    new_lib = CartfileChecker.check_library_by(new_lib, old_lib)
    new_lib
  end
end
