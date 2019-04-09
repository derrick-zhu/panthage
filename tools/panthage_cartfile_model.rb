#!/usr/bin/ruby
# frozen_string_literal: true

require 'singleton'
require_relative 'string_colorize'
require_relative 'panthage_ver_helper'

class ConflictType
  OK = 0
  SKIP = OK + 1
  WARNING = SKIP + 1
  ERROR = WARNING + 1
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
  attr_accessor :conflict_type, :proj_name, :belong_proj_name, :is_new, :error_msg, :dependency
  attr_reader :lib_type

  def initialize(proj_name, belong_proj_name, is_new = true)
    @lib_type = LibType::MAIN
    @conflict_type = ConflictType::OK
    @proj_name = proj_name
    @belong_proj_name = belong_proj_name
    @is_new = is_new
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
    "Library: \'#{proj_name}\' from \'#{belong_proj_name}\' Type:#{lib_type} is_new:#{is_new} "
  end
end

# CartfileGit
class CartfileGit < CartfileBase
  attr_accessor :url, :tag, :branch, :hash
  attr_reader :repo_type

  def initialize(proj_name, belong_proj_name, url, tag, branch)
    super(proj_name, belong_proj_name)

    puts "#{proj_name}, #{url}, #{tag}, #{branch}" if PanConstants.debuging

    @lib_type = LibType::GIT
    @conflict_type = ConflictType::OK
    @error_msg = ''

    @url = !url.nil? ? url : ''
    @tag = !tag.nil? ? tag : ''
    @branch = !branch.nil? ? branch : ''
    @hash = ''

    @repo_type = if !@tag.empty?
                   GitRepoType::TAG
                 elsif !@branch.empty?
                   GitRepoType::BRANCH
                 else
                   GitRepoType::UNKNOWN
                 end
  end

  def description
    if repo_type == GitRepoType::TAG
      super + ", Repo:#{repo_type}, Tag:#{tag}"
    elsif repo_type == GitRepoType::BRANCH
      super + ", Repo:#{repo_type}, Branch:#{branch}"
    end
  end
end

# CartfileBinary
class CartfileBinary < CartfileBase
  attr_accessor :url, :version, :operator

  def initialize(proj_name, belong_proj_name, url, version, operator)
    super(proj_name, belong_proj_name)

    puts "#{proj_name}, #{url}, #{version}, #{operator}" if PanConstants.debuging

    @lib_type = LibType::BINARY
    @conflict_type = ConflictType::OK
    @proj_name = !proj_name.nil? ? proj_name : ''
    @error_msg = ''

    @url = url
    @version = !version.nil? ? version : ''
    @operator = !operator.nil? ? operator : ''
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
