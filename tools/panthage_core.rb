#!/usr/bin/ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'

require_relative 'string_colorize'
require_relative 'panthage_dependency'
require_relative 'panthage_utils'

raise 'wrong args usage' unless ARGV.length >= 3

# GET PARAMETER FROM OUTSIDE
current_dir = ''
scheme_target = ''
job_command = ''

using_carthage = false
using_sync = false
# using_reinstall = false

REG_PARAM = /^-?-(?<key>[\w-]*?)(=(?<value>.*)|)$/.freeze
REG_FLAG = /^-?-(?<key>[\w-]*?)$/.freeze

# reading job description from command line arguments
ARGV.each do |each_arg|
  if REG_FLAG.match?(each_arg)
    match = REG_FLAG.match(each_arg)
    case match[:key]
    when 'using-carthage'
      using_carthage = true
    when 'sync'
      using_sync = true
    # when 'reinstall'
    #   using_reinstall = true
    else
      raise "invalid parameter #{match[:key]}"
    end

  elsif REG_PARAM.match?(each_arg)
    match = REG_PARAM.match(each_arg)
    case match[:key]
    when 'workspace'
      current_dir = match[:value]
    when 'target'
      scheme_target = match[:value]
    when 'command'
      job_command = match[:value]
    else
      raise "invalid parameter #{match[:key]}=#{match[:value]}"
    end

  else
    puts "#{each_arg} ??"
  end
end

# get absolute workspace path
current_dir = File.absolute_path(current_dir)
repo_base = "#{current_dir}/Carthage/Repo"
checkout_base = "#{current_dir}/Carthage/Checkouts"
build_base = "#{current_dir}/Carthage/Build"

# all cartfile info are here, tree
cartfile_main = {}

setup_carthage_env(current_dir.to_s)

new_repos = solve_project_carthage(
  repo_base.to_s,
  scheme_target.to_s,
  current_dir.to_s,
  Command.command_install?(job_command),
  using_sync
)

cartfile_main.merge!(new_repos)

puts cartfile_main.to_s if PanConstants.debuging

new_repos.each do |each_repo|
  puts each_repo.to_s
end
