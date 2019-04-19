#!/usr/bin/ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'

require_relative 'extensions/string_ext'
require_relative 'models/panthage_config'
require_relative 'panthage_dependency'
require_relative 'panthage_utils'
require_relative 'panthage_xcode_config'
require_relative 'panthage_xcode_build'
require_relative 'panthage_cache_version'

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

main_project_info = CartFileBase.new("#{scheme_target}",
                                     'main')

solve_project_carthage(
  main_project_info,
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
  xc_config = XcodeBuildConfigure.new("#{checkout_base}/#{repo_name}",
                                      "#{repo_name}.xcodeproj",
                                      repo_name.to_s,
                                      XcodeBuildConfigure::CONFIG_DEBUG.to_s,
                                      "#{current_dir}/Carthage/.tmp/#{repo_name}",
                                      "#{current_dir}/Carthage/Build/iOS",
                                      'dwarf-with-dsym',
                                      "#{current_dir}/Carthage/Build/iOS")
  xc_config.quiet_mode = true
  # xc_config.sdk = XcodeProjectConfigure::IPHONEOS
  puts '-------------------------------------------------'

  repo_framework.is_ready = XcodeBuilder.build_universal(xc_config)

  framework_cache_version = CacheVersion.new(repo_framework.framework.hash, repo_name, xc_config.framework_version_hash)
  File.write("#{current_dir}/Carthage/Build/.#{xc_config.scheme}.version", JSON.pretty_generate(framework_cache_version.to_json))

  raise "fatal: error in build '#{repo_name}'.xcodeproj." unless repo_framework.is_ready

  # next one
  repo_framework = ProjectCartManager.instance.any_repo_framework
end

puts '-------------------------------------------------'
puts 'DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!'
