#!/usr/bin/ruby
# frozen_string_literal: true

# PanConstants constants for panthage
class PanConstants
  @@debugging = false
  @@maximum_dummy_number_in_template = 10

  @@quiet = '--quiet'

  def self.disable_verbose
    PanConstants.debugging ? '' : @@quiet
  end

  def self.debugging
    @@debugging
  end

  # dummy fw count (max)
  def self.max_dummy_template
    @@maximum_dummy_number_in_template
  end

  def initialize; end
end

