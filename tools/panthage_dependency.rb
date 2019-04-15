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

# main command
class Command
  CMD_UNKNOWN = -1
  CMD_INSTALL = CMD_UNKNOWN + 1
  CMD_UPDATE = CMD_INSTALL + 1
  CMD_BOOTSTRAP = CMD_UPDATE + 1

  def self.command_install?(cmd)
    cmd == CMD_INSTALL
  end

  def self.command_update?(cmd)
    cmd == CMD_UPDATE
  end

  def self.command_bootstrap?(cmd)
    cmd == CMD_BOOTSTRAP
  end
end
