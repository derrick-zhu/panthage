#!/usr/bin/ruby
# frozen_string_literal: true

class Base
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def say
    puts self.words
  end

  def words
    "Hello #{value}"
  end
end

class ChildA < Base
  attr_accessor :valueA

  def initialize(value, valueA)
    @value = value
    @valueA = valueA
  end

  def words
    "Hello #{valueA}, and #{value}"
  end
end

def some_one_said(someone)
    someone.say()
end

aBase = Base.new('world')
aBase.say

aChildA = ChildA.new('John', 'Johson')
aChildA.say

some_one_said(aBase)
some_one_said(aChildA)

puts aBase.value
puts aChildA.value
