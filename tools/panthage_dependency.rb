#!/usr/bin/ruby
# frozen_string_literal: true

# PanConstants constants for panthage
class PanConstants
  DEBUGGING = true
  QUIET = '--quiet'

  def self.disable_verbose
    PanConstants.debugging ? '' : QUIET
  end

  def self.debugging
    DEBUGGING
  end

  def initialize; end
end

