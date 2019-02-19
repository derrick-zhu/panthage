#!/usr/bin/ruby
# frozen_string_literal: true

class ConflictType
  OK = 0
  WARNING = OK + 1
  ERROR = WARNING + 1
end

class LibType
  GIT = 0
  BINARY = GIT + 1
  GITHUB = BINARY + 1
end

class GitRepoType
  UNKNOWN = -1
  TAG = 0
  BRANCH = TAG + 1
end

class CartfileBase
  attr_accessor :conflict_type, :proj_name, :is_new, :error_msg
  attr_reader :lib_type

  def initialize
    @lib_type = LibType::GIT
    @conflict_type = ConflictType::OK
    @proj_name = ''
    @is_new = false
    @error_msg = ''
  end
end

class CartfileGit < CartfileBase
  attr_accessor :repo_type, :url, :tag, :branch, :hash

  def initialize(proj_name, url, tag, branch)
    puts "#{proj_name}, #{url}, #{tag}, #{branch}"

    @lib_type = LibType::GIT
    @conflict_type = ConflictType::OK
    @proj_name = proj_name
    @is_new = true
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
end

class CartfileBinary < CartfileBase
  attr_accessor :url, :version, :operator

  def initialize(proj_name, url, version, operator)
    puts "#{proj_name}, #{url}, #{version}, #{operator}"

    @lib_type = LibType::BINARY
    @conflict_type = ConflictType::OK
    @proj_name = !proj_name.nil? ? proj_name : ''
    @is_new = true
    @error_msg = ''

    @url = url
    @version = !version.nil? ? version : ''
    @operator = !operator.nil? ? operator : ''
  end
end

class CartfileGithub < CartfileBase
  # TODO: need to be done about github library denpendency
end

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
