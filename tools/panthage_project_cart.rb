#!/usr/bin/ruby
# frozen_string_literal: true

require 'singleton'
require_relative 'string_colorize'
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

    verify_library_compatible(old_lib, new_lib) unless old_lib.nil?

    puts new_lib.description.bg_gray.red.to_s

    frameworks[new_lib.proj_name] = FrameworkBuildInfo.new(new_lib.proj_name, new_lib) unless new_lib.conflict_type == ConflictType::ERROR
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

  def verify_library_compatible(liba, libb)
    raise "could not verfiy library compatible between \'#{liba.proj_name}\' and \'#{libb.proj_name}\'" if liba.proj_name != libb.proj_name
    raise "incompatible library type: \n\t\'#{liba.proj_name}\'(#{liba.belong_proj_name}) -> #{liba.lib_type}\n and \n\t\'#{libb.proj_name}\'(#{libb.belong_proj_name}) -> #{liba.lib_type}" if liba.lib_type != libb.lib_type
    raise "incompatible library repo type: \n\t\'#{liba.proj_name}\'(#{liba.belong_proj_name}) -> #{liba.repo_type}\n and \n\t\'#{libb.proj_name}\'(#{libb.belong_proj_name}) -> #{liba.repo_type}" if liba.repo_type != libb.repo_type

    case liba.lib_type
    when LibType::GIT, LibType::GITHUB
      if !libb.tag.nil? && !liba.tag.nil?
        new_major = VersionHelper.major_no(libb.tag)
        new_minor = VersionHelper.minor_no(libb.tag)
        old_major = VersionHelper.major_no(liba.tag)
        old_minor = VersionHelper.minor_no(liba.tag)

        if new_major != old_major
          liba.conflict_type = ConflictType::ERROR
          liba.error_msg = show_conflict_git(libb, liba)
          raise "halt !!! #{liba.error_msg}"
        elsif new_minor != old_minor
          libb.conflict_type = ConflictType::WARNING
          libb.error_msg = "warning: #{new_name} version update #{liba.tag} -> #{libb.tag}"
          return libb
        else
          libb.conflict_type = ConflictType::OK
          return libb
        end
      elsif !libb.branch.nil? && !liba.branch.nil?
        unless (libb.url == liba.url) && (libb.branch == liba.branch)
          liba.conflict_type = ConflictType::ERROR
          liba.error_msg = show_conflict_branch(libb, liba)
          raise "halt !!! #{liba.error_msg}"
        end
      elsif !libb.branch.nil? && !liba.tag.nil?
        libb.conflict_type = ConflictType::WARNING
        libb.error_msg = "warning: #{new_name} framework update: #{liba.tag} -> #{libb.url}:#{libb.branch}"
        return libb
      end

    when LibType::BINARY
      new_url = libb.url
      new_version = libb.version

      old_url = liba.url
      old_version = liba.version

      unless new_url == old_url
        liba.conflict_type = ConflictType::ERROR
        liba.error_msg = "conflict framework library #{old_name} had the conflict url: \n #{liba.url} \nand\n #{new_dat.url} "
        raise "halt !!! #{liba.error_msg}"
      end

      new_major = VersionHelper.major_no(new_version)
      new_minor = VersionHelper.minor_no(new_version)
      new_build = VersionHelper.build_no(new_version)

      old_major = VersionHelper.major_no(old_version)
      old_minor = VersionHelper.minor_no(old_version)
      old_build = VersionHelper.build_no(old_version)

      if new_major != old_major
        liba.conflict_type = ConflictType::ERROR
        liba.error_msg = "conflict framework version:\n#{libb.version} by #{libb.proj_name}\n#{liba.version} by #{liba.proj_name}"
        raise "halt !!! #{liba.error_msg}"

      elsif new_minor != old_minor
        libb.conflict_type = ConflictType::WARNING
        libb.error_msg = "warning: #{new_name} version update #{liba.version} -> #{libb.version}"
        return libb

      elsif new_build > old_build
        libb.conflict_type = ConflictType::OK
        return libb
      end

    end # end case of liba.lib_type
  end
end
