#!/usr/bin/ruby
# frozen_string_literal: true

module ConflictType
  OK = 0
  WARNING = OK + 1
  ERROR = WARNING + 1
end

# Cartfile class for basic information about cartfile
class Cartfile
  # conflict means current library is a conflict dependency library for :proj_name
  attr_reader :conflict
  attr_writer :conflict

  # proj_name is a project name which the current library dependented by.
  attr_reader :proj_name
  attr_writer :proj_name

  attr_reader :is_new
  attr_writer :is_new

  attr_reader :type
  attr_writer :type

  attr_reader :url
  attr_writer :url

  attr_reader :tag
  attr_writer :tag

  attr_reader :branch
  attr_writer :branch

  attr_reader :version
  attr_writer :version

  attr_reader :operator
  attr_writer :operator

  attr_reader :hash
  attr_writer :hash

  attr_reader :error_msg
  attr_writer :error_msg

  def initialize(proj_name, type, url, tag = nil, branch = nil, version = nil, operator = nil, conflict = ConflicType.OK)
    @conflict = conflict
    @proj_name = proj_name
    @is_new = true
    @type = type
    @url = url
    @tag = tag
    @branch = branch
    @version = version
    @operator = operator
    @hash = nil

    @error_msg = ''
  end

  def self.new_git(proj_name, type, url, tag, branch, conflict = false)
    Cartfile.new(proj_name, type, url, tag, branch, conflict)
  end

  def self.new_binary(proj_name, type, url, version, operator, conflict = false)
    Cartfile.new(proj_name, type, url, nil, nil, version, operator, conflict)
  end

end

class CartfileResolved
  attr_reader :name
  attr_writer :name

  attr_reader :type
  attr_writer :type

  attr_reader :url
  attr_writer :url

  attr_reader :hash
  attr_writer :hash

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
