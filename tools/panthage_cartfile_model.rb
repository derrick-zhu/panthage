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

# CartFileBase base git repo class
class CartFileBase
  attr_accessor :name,
                :parent_project_name,
                :conflict_type,
                :version,
                :hash,
                :error_msg,
                :dependency
  attr_reader :lib_type

  def initialize(name, parent_name, version = '')
    @lib_type = LibType::MAIN
    @conflict_type = ConflictType::IGNORE
    @name = name
    @parent_project_name = parent_name
    @version = !version.nil? ? version : ''
    @error_msg = ''
    @dependency = []
    @hash = ''
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
    "Library: #{name} from #{parent_project_name} Type:#{lib_type} "
  end
end

# CartFileGit
class CartFileGit < CartFileBase
  attr_accessor :url,
                :branch,
                :compare_method
  attr_reader :repo_type

  def initialize(project_name, parent_name, url, tag, branch, compare_method = '~>')
    super(project_name, parent_name, tag)

    puts "#{project_name}, #{url}, #{version}, #{branch}" if PanConstants.debugging

    @lib_type = LibType::GIT
    @conflict_type = ConflictType::IGNORE
    @error_msg = ''

    @url = !url.nil? ? url : ''
    @branch = !branch.nil? ? branch : ''
    @compare_method = compare_method

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
      super + ", Repo:#{repo_type}, Tag:#{version}, Hash: #{hash}"
    elsif repo_type == GitRepoType::BRANCH
      super + ", Repo:#{repo_type}, Branch:#{branch}, Hash: #{hash}"
    end
  end
end

# CartFileGithub
class CartFileGithub < CartFileGit
  def initialize(name, parent_name, url, tag, branch, compare_method = '~>')
    super(name, parent_name, url, tag, branch, compare_method)
  end

  def description
    super
  end
end

# CartFileBinary
class CartFileBinary < CartFileBase
  attr_accessor :url, :operator

  def initialize(name, project_name, url, version, operator)
    super(name, project_name, version)

    @lib_type = LibType::BINARY
    @conflict_type = ConflictType::IGNORE
    @error_msg = ''
    @url = url
    @operator = !operator.nil? ? operator : ''

    puts "#{name}, #{url}, #{version}, #{operator}" if PanConstants.debugging
  end

  def description
    super + ", Version: #{version}, Final Version: #{hash}"
  end
end

# CartfileResolved
class CartFileResolved
  attr_reader :name, :type, :url, :hash

  def initialize(name, type, url, hash)
    @name = name
    @type = type
    @url = url
    @hash = hash
  end

  def self.new_cart_solved(name, type, url, hash)
    CartFileResolved.new(name, type, url, hash)
  end
end

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
    end # end of case
  end # end of method `check_library_by`

  private

  def msg_conflict_tag(new_data, old_data)
    "conflict framework version:\n\t#{new_data.version} by #{new_data.name}\tand\n\t#{old_data.version} by #{old_data.name}"
  end

  def msg_conflict_branch(new_data, old_data)
    "conflict framework version:\n\t#{new_data.branch} by #{new_data.name}\tand\n\t#{old_data.branch} by #{old_data.name}"
  end
end
