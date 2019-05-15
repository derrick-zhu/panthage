#!/usr/bin/ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'

require_relative 'command/command_factory'
require_relative 'models/panthage_cmdline'

raise "fatal: wrong args usage #{ARGV}" unless ARGV.length >= 3

cmd = CommandFactory.get_command(CommandLine.instance.parse(ARGV))
unless cmd.nil?
  cmd.setup
  cmd.execute
  cmd.finalize
end
