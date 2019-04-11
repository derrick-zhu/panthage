#!/usr/bin/ruby
# frozen_string_literal: true

require 'singleton'
require_relative 'string_ext'
require_relative 'panthage_ver_helper'

class ConflictType
  IGNORE = 0
  ACCEPT = IGNORE + 1
  ERROR = ACCEPT + 1
end

class LibType
  MAIN = 0
  GIT = MAIN + 1
  BINARY = GIT + 1
  GITHUB = BINARY + 1
end

class GitRepoType
  UNKNOWN = -1
  TAG = 0
  BRANCH = TAG + 1
end

class CartfileBase
  attr_accessor :proj_name,
                :belong_proj_name,
                :conflict_type,
                :version,
                :error_msg,
                :dependency
  attr_reader :lib_type

  def initialize(proj_name, belong_proj_name, version = '')
    @lib_type = LibType::MAIN
    @conflict_type = ConflictType::IGNORE
    @proj_name = proj_name
    @belong_proj_name = belong_proj_name
    @version = !version.nil? ? version : ''
    @error_msg = ''
    @dependency = []
  end

  def append_dependency(new_lib)
    dependency.push(new_lib)
  end

  def number_of_dependency
    dependency.length
  end

  def dependency_with_index(idx)
    dependency[idx] if idx.negative? || idx >= dependency.length
  end

  def description
    "Library: \'#{proj_name}\' from \'#{belong_proj_name}\' Type:#{lib_type} "
  end
end

# CartfileGit
class CartfileGit < CartfileBase
  attr_accessor :url,
                :branch,
                :hash
  attr_reader :repo_type

  def initialize(proj_name, belong_proj_name, url, tag, branch)
    super(proj_name, belong_proj_name, tag)

    puts "#{proj_name}, #{url}, #{version}, #{branch}" if PanConstants.debuging

    @lib_type = LibType::GIT
    @conflict_type = ConflictType::IGNORE
    @error_msg = ''

    @url = !url.nil? ? url : ''
    @branch = !branch.nil? ? branch : ''
    @hash = ''

    @repo_type = if !version.empty?
                   GitRepoType::TAG
                 elsif !@branch.empty?
                   GitRepoType::BRANCH
                 else
                   GitRepoType::UNKNOWN
                 end
  end

  def description
    if repo_type == GitRepoType::TAG
      super + ", Repo:#{repo_type}, Tag:#{version}"
    elsif repo_type == GitRepoType::BRANCH
      super + ", Repo:#{repo_type}, Branch:#{branch}"
    end
  end
end

# CartfileBinary
class CartfileBinary < CartfileBase
  attr_accessor :url, :operator

  def initialize(proj_name, belong_proj_name, url, version, operator)
    super(proj_name, belong_proj_name, version)

    @lib_type = LibType::BINARY
    @conflict_type = ConflictType::IGNORE
    @proj_name = !proj_name.nil? ? proj_name : ''
    @error_msg = ''
    @url = url
    @operator = !operator.nil? ? operator : ''

    puts "#{proj_name}, #{url}, #{version}, #{operator}" if PanConstants.debuging
  end

  def description
    super + ", Version: #{version}"
  end
end

# CartfileGithub
class CartfileGithub < CartfileBase
  # TODO: need to be done about github library dependency
end

# CartfileResolved
class CartfileResolved
  attr_reader :name, :type, :url, :hash

  def initialize(name, type, url, hash)
    @name = name
    @type = type
    @url = url
    @hash = hash
  end

  def self.new_cart_solved(name, type, url, hash)
    CartfileResolved.new(name, type, url, hash)
  end
end

# CartfileChecker for checking library's version acceptable logic
class CartfileChecker
  def self.check_library_by(new_data, old_data)
    case old_data.lib_type
    when LibType::GIT, LibType::GITHUB
      if !new_data.version.empty? && !old_data.version.empty?
        new_major = VersionHelper.major_no(new_data.version)
        new_minor = VersionHelper.minor_no(new_data.version)
        new_build = VersionHelper.build_no(new_data.version)
        old_major = VersionHelper.major_no(old_data.version)
        old_minor = VersionHelper.minor_no(old_data.version)
        old_build = VersionHelper.build_no(new_data.version)

        if new_major != old_major
          new_data.conflict_type = ConflictType::ERROR
          new_data.error_msg = show_conflict_git(new_data, old_data)
        elsif (new_minor > old_minor) || ((new_minor == old_minor) && (new_build > old_build))
          new_data.conflict_type = ConflictType::ACCEPT
        else
          new_data.conflict_type = ConflictType::IGNORE
        end

      elsif !new_data.branch.empty? && !old_data.branch.empty?
        if (new_data.url == old_data.url) && (new_data.branch == old_data.branch)
          new_data.conflict_type == ConflictType::IGNORE
        else
          new_data.conflict_type = ConflictType::ERROR
          new_data.error_msg = show_conflict_branch(new_data, old_data)
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
        old_data.error_msg = "conflict framework version:\n#{new_data.version} by #{new_data.proj_name}\n#{old_data.version} by #{old_data.proj_name}"
        raise "halt !!! #{old_data.error_msg}"
      elsif (new_minor > old_minor) || ((new_minor == old_minor) && (new_build > old_build))
        new_data.conflict_type = ConflictType::ACCEPT
      else
        new_data.conflict_type = ConflictType::IGNORE
      end
    end # end of case
  end # end of method `check_library_by`
end
