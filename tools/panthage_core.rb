#!/usr/bin/ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'

require_relative 'models/pconfig'
require_relative 'string_colorize'
require_relative 'panthage_dependency'
require_relative 'panthage_utils'

raise 'wrong args usage' unless ARGV.length >= 3

rt_config = ExecuteConfig.new(ARGV)

scheme_target = rt_config.scheme_target
job_command = rt_config.job_command
using_sync = rt_config.using_sync

# get absolute workspace path
current_dir = rt_config.current_dir
repo_base = rt_config.repo_base
checkout_base = rt_config.checkout_base
build_base = rt_config.build_base

# all cartfile info are here, tree
cartfile_main = {}

setup_carthage_env(current_dir.to_s)

main_project_info = solve_project_carthage(
  current_dir.to_s,
  scheme_target.to_s,
  'main',
  current_dir.to_s,
  Command.command_install?(job_command),
  using_sync
)

puts main_project_info.to_s if PanConstants.debuging

solve_project_dependency(
  main_project_info,
  current_dir.to_s,
  Command.command_install?(job_command),
  using_sync
)

puts ProjectCartManager.instance.description.red.bg_gray.to_s

# build the source dependency framework
repo_framework = ProjectCartManager.instance.any_repo_framework
until repo_framework.nil? || repo_framework.is_ready || repo_framework.framework.nil?

  puts repo_framework.description.to_s

  repo_framework.is_ready = true
  repo_framework = ProjectCartManager.instance.any_repo_framework
end

puts 'DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!'
