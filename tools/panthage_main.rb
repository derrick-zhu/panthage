#!/usr/bin/ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'

require_relative 'string_ext'
require_relative 'models/panthage_config'
require_relative 'panthage_dependency'
require_relative 'panthage_utils'
require_relative 'panthage_xcode_config'
require_relative 'panthage_xcode_build'

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

setup_carthage_env(current_dir.to_s)

main_project_info = solve_project_carthage(
  current_dir.to_s,
  scheme_target.to_s,
  'main',
  current_dir.to_s,
  Command.command_install?(job_command),
  using_sync
)

puts main_project_info.to_s if PanConstants.debugging

solve_project_dependency(
  main_project_info,
  current_dir.to_s,
  Command.command_install?(job_command),
  using_sync
)

puts ProjectCartManager.instance.description.reverse_color.to_s

# build the source dependency framework
repo_framework = ProjectCartManager.instance.any_repo_framework

until repo_framework.nil? || repo_framework.is_ready || repo_framework.framework.nil?

  repo_name = repo_framework.name.to_s
  xc_config = XcodeProjectConfigure.new("#{checkout_base}/#{repo_name}/",
                                        "#{repo_name}.xcodeproj",
                                        "#{repo_name}",
                                        'Debug',
                                        'iphoneos',
                                        "#{current_dir}/Carthage/.tmp/#{repo_name}/",
                                        "#{current_dir}/Carthage/Build/iOS/",
                                        'dwarf-with-dsym',
                                        "#{current_dir}/Carthage/Build/iOS/")
  puts '-------------------------------------------------'
  # puts repo_framework.description.to_s
  # puts "#{xc_config.to_xc} #{xc_config.to_xc_param}"

  repo_framework.is_ready = XcodeBuilder.build(xc_config)
  puts repo_framework.is_ready.to_s

  raise "fatal: error in build '#{repo_name}'.xcodeproj." unless repo_framework.is_ready

  # next one
  repo_framework = ProjectCartManager.instance.any_repo_framework
end

puts '-------------------------------------------------'
puts 'DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!'
