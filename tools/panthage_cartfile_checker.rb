#!/usr/bin/ruby
# frozen_string_literal: true

require_relative 'panthage_ver_helper'

# CartFileChecker for checking library's version acceptable logic
class CartFileChecker
  def self.check_library_by(new_data, old_data)
    case old_data.lib_type
    when LibType::GIT, LibType::GITHUB
      if !new_data.version.empty? && !old_data.version.empty?
        new_major = VersionHelper.major_no(new_data.version)
        new_minor = VersionHelper.minor_no(new_data.version)
        new_build = VersionHelper.build_no(new_data.version)
        old_major = VersionHelper.major_no(old_data.version)
        old_minor = VersionHelper.minor_no(old_data.version)
        old_build = VersionHelper.build_no(old_data.version)

        if new_major != old_major
          new_data.conflict_type = ConflictType::ERROR
          new_data.error_msg = msg_conflict_tag(new_data, old_data)
        elsif (new_minor > old_minor) ||
              ((new_minor == old_minor) && (new_build > old_build))
          new_data.conflict_type = ConflictType::ACCEPT
        else
          new_data.conflict_type = ConflictType::IGNORE
        end

      elsif !new_data.branch.empty? && !old_data.branch.empty?
        if (new_data.url == old_data.url) && (new_data.branch == old_data.branch)
          new_data.conflict_type == ConflictType::IGNORE
        else
          new_data.conflict_type = ConflictType::ERROR
          new_data.error_msg = msg_conflict_branch(new_data, old_data)
        end

      elsif !new_data.version.empty? && !old_data.branch.empty?
        new_data.conflict_type == ConflictType::IGNORE

      elsif !new_data.branch.empty? && !old_data.version.empty?
        new_data.conflict_type = ConflictType::ACCEPT
        new_data.error_msg = "warning: #{new_name} framework update: #{old_data.version} -> #{new_data.url}:#{new_data.branch}"

      else
        raise "unknown condition: \n\t#{old_data.description}\nand\n\t#{new_data.description}"
      end

    when LibType::BINARY
      new_url = new_data.url
      new_version = new_data.version

      old_url = old_data.url
      old_version = old_data.version

      unless new_url == old_url
        new_data.conflict_type = ConflictType::ERROR
        new_data.error_msg = "conflict framework library #{old_name} had the conflict url: \n #{old_data.url} \nand\n #{new_dat.url} "
      end

      new_major = VersionHelper.major_no(new_version)
      new_minor = VersionHelper.minor_no(new_version)
      new_build = VersionHelper.build_no(new_version)

      old_major = VersionHelper.major_no(old_version)
      old_minor = VersionHelper.minor_no(old_version)
      old_build = VersionHelper.build_no(old_version)

      if new_major != old_major
        old_data.conflict_type = ConflictType::ERROR
        old_data.error_msg = "conflict framework version:\n#{new_data.version} by #{new_data.name}\n#{old_data.version} by #{old_data.name}"
        raise "halt !!! #{old_data.error_msg}"
      elsif (new_minor > old_minor) || ((new_minor == old_minor) && (new_build > old_build))
        new_data.conflict_type = ConflictType::ACCEPT
      else
        new_data.conflict_type = ConflictType::IGNORE
      end
    end
  end

  private

  def msg_conflict_tag(new_data, old_data)
    "conflict framework version:\n\t#{new_data.version} by #{new_data.name}\tand\n\t#{old_data.version} by #{old_data.name}"
  end

  def msg_conflict_branch(new_data, old_data)
    "conflict framework version:\n\t#{new_data.branch} by #{new_data.name}\tand\n\t#{old_data.branch} by #{old_data.name}"
  end
end
