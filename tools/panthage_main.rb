#!/usr/bin/ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'

require_relative 'extensions/fileutils_ext'
require_relative 'extensions/string_ext'
require_relative 'models/panthage_cmdline'
require_relative 'models/panthage_xc_scheme_model'
require_relative 'panthage_dependency'
require_relative 'panthage_utils'
require_relative 'panthage_xcode_builder_config'
require_relative 'panthage_xcode_builder'
require_relative 'panthage_cache_version'

raise "fatal: wrong args usage #{ARGV}" unless ARGV.length >= 3

CommandLine.instance.parse(ARGV)
rt_config = CommandLine.instance

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
    CommandLine.install?(job_command),
    using_sync
)

puts main_project_info.to_s if PanConstants.debugging

solve_project_dependency(
    main_project_info,
    current_dir.to_s,
    CommandLine.install?(job_command),
    using_sync
)

puts ProjectCartManager.instance.description.reverse_color.to_s

puts ProjectCartManager.instance.resolved_info
FileUtils.remove_entry "#{rt_config.current_dir}/Cartfile.resolved" if File.exist?"#{rt_config.current_dir}/Cartfile.resolved"
File.open "#{rt_config.current_dir}/Cartfile.resolved", File::RDWR|File::CREAT, 0644 do |fp|
  fp.rewind
  fp.write ProjectCartManager.instance.resolved_info
  fp.flush
  fp.truncate(fp.pos)
end

# build the source dependency framework
repo_framework = ProjectCartManager.instance.any_repo_framework
until repo_framework&.is_ready || repo_framework&.framework.nil?
  repo_name = repo_framework.name.to_s

  unless File.exist? "#{checkout_base}/#{repo_name}/"
    # next one
    repo_framework = ProjectCartManager.instance.any_repo_framework
    next
  end

  # 将当前目录设置成操作目录。
  Dir.chdir("#{checkout_base}/#{repo_name}/")

  xcode_project_file_path = FileUtils.find_path_in_r("#{repo_name}.xcodeproj", '.', '')
  if xcode_project_file_path.empty?
    raise "#{"***".cyan} could not find and build #{repo_name.green.bold}"
  end

  xcode_proj_file = xcode_project_file_path.first.to_s

  p_xcode_project = XcodeProject.new(xcode_proj_file.to_s,
                                     XcodeBuildConfigure::DEBUG,
                                     rt_config.platform)

  xc_build_result = true
  p_xcode_project.targets.each do |xc_target|
    next if xc_target.platform_type != rt_config.platform

    build_dir_path = "#{current_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(xc_target.platform_type)}"
    version_hash_filepath = ''
    build_scheme_name = ''

    if xc_target.static? or xc_target.mach_o_static?
      build_dir_path = "#{current_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(xc_target.platform_type)}/Static"
      version_hash_filepath = "#{current_dir}/Carthage/Build/.#{xc_target.product_name}.static.version"
      build_scheme_name = p_xcode_project.scheme_for_target(xc_target.target_name).name
    elsif xc_target.dylib?
      build_dir_path = "#{current_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(xc_target.platform_type)}"
      version_hash_filepath = "#{current_dir}/Carthage/Build/.#{xc_target.product_name}.dynamic.version"
      build_scheme_name = p_xcode_project.scheme_for_target(xc_target.target_name).name
    else
      next
    end

    xc_config = XcodeBuildConfigure.new("#{checkout_base}/#{repo_name}",
                                        "#{xcode_proj_file}",
                                        "#{build_scheme_name}",
                                        XcodeBuildConfigure::DEBUG,
                                        "#{current_dir}/Carthage/.tmp/#{repo_name}",
                                        "#{current_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(xc_target.platform_type)}",
                                        'dwarf-with-dsym',
                                        "#{build_dir_path}",
                                        rt_config.platform)
    xc_config.quiet_mode = !rt_config.verbose
    puts '-------------------------------------------------'

    xc_build_result &&= XcodeBuilder.build_universal(xc_config, xc_target)

    unless version_hash_filepath.nil? || version_hash_filepath.empty?
      framework_cache_version = CacheVersion.new(repo_framework.framework.hash, repo_name, xc_config.framework_version_hash)
      File.write(version_hash_filepath.to_s, JSON.pretty_generate(framework_cache_version.to_json))
    end
  end

  repo_framework.is_ready = xc_build_result
  raise "fatal: error in build '#{xcode_proj_file}." unless repo_framework.is_ready

  # next one
  repo_framework = ProjectCartManager.instance.any_repo_framework
end

puts '-------------------------------------------------'
puts 'DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!'
