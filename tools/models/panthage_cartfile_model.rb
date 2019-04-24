#!/usr/bin/ruby
# frozen_string_literal: true

require 'singleton'
require_relative '../extensions/string_ext'
require_relative '../panthage_ver_helper'

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
                :dependency,
                :raw_dependency

  attr_reader :lib_type,
              :is_private

  def initialize(name, parent_name, version = '', is_private = false)
    @lib_type = LibType::MAIN
    @conflict_type = ConflictType::IGNORE
    @name = name
    @parent_project_name = parent_name
    @version = !version.nil? ? version : ''
    @is_private = is_private
    @error_msg = ''
    @dependency = []
    @raw_dependency = []
    @hash = ''
  end

  def append_raw_dependency(new_lib)
    raw_dependency.push(new_lib)
  end

  def description
    dependency_descs = []
    dependency.each { |lib| dependency_descs.push(lib.name) }
    "Library: #{name} from #{parent_project_name} Type:#{lib_type} Dependency: [#{dependency_descs.join( ',')}]"
  end
end

# CartFileGit
class CartFileGit < CartFileBase
  attr_accessor :url,
                :branch,
                :compare_method
  attr_reader :repo_type

  def initialize(project_name, parent_name, url, tag, branch, compare_method = '~>', is_private)
    super(project_name, parent_name, tag, is_private)

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
  def initialize(name, parent_name, url, tag, branch, compare_method = '~>', is_private = false)
    super(name, parent_name, url, tag, branch, compare_method, is_private)
  end

  def description
    super
  end
end

# CartFileBinary
class CartFileBinary < CartFileBase
  attr_accessor :url, :operator

  def initialize(name, project_name, url, version, operator, is_private = false)
    super(name, project_name, version, is_private)

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
