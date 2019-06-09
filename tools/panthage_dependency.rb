#!/usr/bin/ruby
# frozen_string_literal: true

# PanConstants constants for panthage
class PanConstants
  @DEBUGGING = false
  @QUIET = '--quiet'

  def initialize; end

  def self.disable_verbose
    PanConstants.debugging ? '' : @QUIET
  end

  def self.debugging
    @DEBUGGING
  end

  def self.debugging=(new_value)
    @DEBUGGING = new_value
  end
end

