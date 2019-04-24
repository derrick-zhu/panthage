#!/usr/bin/ruby
# frozen_string_literal: true

require 'singleton'
require_relative 'extensions/string_ext'
require_relative 'models/panthage_cartfile_model'
require_relative 'panthage_ver_helper'
require_relative 'panthage_cartfile_checker'

# FrameworkBuildTable
class FrameworkBuildInfo
  attr_reader :name,
              :framework
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
    framework.dependency.each do |each_lib|
      result &&= ProjectCartManager.instance.framework_ready?(each_lib.name)
      break unless result
    end

    result
  end

  def description
    "Framework :#{name}, is_ready:#{is_ready}, info:#{framework.description}"
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

  def update_framework(new_lib)
    raise "invalid library '#{new_lib}'" if new_lib.nil?

    frameworks[new_lib.name] = FrameworkBuildInfo.new(new_lib.name, new_lib)
  end

  def framework_with_name(name)
    frameworks[name].framework if frameworks.key?(name)
  end

  def build_info_with_name(name)
    frameworks[name] if frameworks.key?(name)
  end

  def framework_ready?(name)
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

  def verify_library_compatible(new_lib, old_lib)
    raise "could not verify library compatible between #{new_lib.name} and #{old_lib.name}" if new_lib.name != old_lib.name
    raise "incompatible library type: \n\t#{new_lib.name}(#{new_lib.parent_project_name}) -> #{new_lib.lib_type}\n and \n\t#{old_lib.name}(#{old_lib.parent_project_name}) -> #{new_lib.lib_type}" if new_lib.lib_type != old_lib.lib_type
    raise "incompatible library repo type: \n\t#{new_lib.name}(#{new_lib.parent_project_name}) -> #{new_lib.repo_type}\n and \n\t#{old_lib.name}(#{old_lib.parent_project_name}) -> #{new_lib.repo_type}" if new_lib.repo_type != old_lib.repo_type

    CartFileChecker.check_library_by(new_lib, old_lib)
  end
end
