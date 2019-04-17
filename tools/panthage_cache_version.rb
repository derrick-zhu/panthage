#!/usr/bin/ruby
# frozen_string_literal: true

class CachePlatform
  attr_accessor :name, :hash
  def initialize(name, hash)
    @name = name
    @hash = hash
  end

  def to_json
    {
      name: @name.to_s,
      hash: @hash.to_s
    }
  end
end

class CacheVersion
  attr_accessor :commitish, :iOS

  def initialize(commitish, name, hash)
    @commitish = commitish
    @iOS = CachePlatform.new(name, hash)
  end

  def to_json
    {
      commitish: @commitish.to_s,
      iOS: [@iOS.to_json]
    }
  end
end
