#!/usr/bin/ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'

require_relative 'command/command_factory'
require_relative 'models/panthage_cmdline'

raise "fatal: wrong args usage #{ARGV}" unless ARGV.length >= 3

def show_help_info
  puts "********** help screen ************"
end

cmd = CommandFactory.get_command(CommandLine.instance.parse(ARGV))
if cmd.nil?
  show_help_info
  exit
end

cmd.setup
cmd.execute
cmd.finalize