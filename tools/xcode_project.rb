#!/usr/bin/ruby
# frozen_string_literal: true

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'

require_relative 'string_colorize'
require_relative 'panthage_dependency'
require_relative 'panthage_file'

#
# Parameters list
# 0: workspace directory
# 1: project name
#

# $panda_dep_table[:Panda].each do |value|
#   puts "#{value}"
# end

# exit

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

# TODO: read for reading cartfile and cartfile.resolved
cartfile = {}
cartfile_resolved = {}

# get absolute workspace path
current_dir = File.absolute_path(current_dir)
repo_base = "#{current_dir}/Carthage/Repo"
checkout_base = "#{current_dir}/Carthage/Checkouts"
build_base = "#{current_dir}/Carthage/Build"

setup_carthage_env(current_dir.to_s)

# analysis the Cartfile to grab workspace's basic information
cartfile.merge!(read_cart_file(scheme_target.to_s, "#{current_dir}/Cartfile"))
cartfile.merge!(read_cart_file(scheme_target.to_s, "#{current_dir}/Cartfile.private"))

# after merged cartfile data, before next parse cartfile detail, pls check the `conflict` property of the `Cartfile` instance. 

# setup and sync git repo
cartfile.select { |_, v| GitRepo.type(v) == GitRepoType::TAG }
        .each do |name, value|
  clone_bare_repo(repo_base, name, value, command_install?(job_command))
end

# generate Cartfile.resolved file.
solve_cart_file(current_dir.to_s, cartfile, using_carthage)

# read the latest version of Cartfile.resolved file.
cartfile_resolved = read_cart_solved_file(current_dir.to_s)

# fetch binary framework first
cartfile_resolved.select { |_, value| value.type == 'binary' }
                 .each do |name, value|
  puts name.to_s + ': ' + value.to_s if PanConstants.debuging
  download_binary_file(value.url, value.hash, "#{current_dir}/Carthage/.tmp/#{name}.zip")
end

# deal with git repo first
cartfile_resolved.select { |_, value| value.type == 'git' }
                 .each do |name, _|
  command = "git init --separate-git-dir=#{current_dir}/Carthage/Repo/#{name}.git;"
  command += if using_sync
               'git reset --hard -q; git pull;'
             else
               'git reset -q;'
             end

  system("cd #{current_dir}; carthage bootstrap --platform iOS --verbose --no-build #{name};" \
      + "mkdir -p #{current_dir}/Carthage/Checkouts/#{name}/Carthage/ ; cd $_ ;" \
      + "ln -s #{current_dir}/Carthage/Build . ; cd #{current_dir}/Carthage/Checkouts/#{name}/;" \
      + command)
  next if using_sync
end

# project_path = current_dir + '/' + scheme_target + '.xcodeproj'
# # puts "project_path: "+project_path.to_s

# xcodeproj = Xcodeproj::Project.open(project_path)
# # puts xcodeproj.to_s

# app_target = xcodeproj.targets.find { |st| st.name == scheme_target }
# # puts app_target.to_s

# # ****************************

# # dummy_targets = Array.new

# # for i in 1..PanConstants.max_dummy_template
# #     dummy_target_name = "Dummy#{i}"
# #     dummy_target = xcodeproj.targets.find { |nt| nt.name == dummy_target_name}
# #     dummy_target.dependencies.clear
# #     dummy_targets.insert(i, dummy_target)
# #     app_target.add_dependency(dummy_target)
# # end

# # for i in 1..(PanConstants.max_dummy_template - 1)
# #     for j in (i + 1)..PanConstants.max_dummy_template
# #         dummy_targets[i].add_dependency(dummy_targets[j])
# #     end
# # end

# # *************************
# target_links = app_target.frameworks_build_phases

# # embed app extensions.
# app_embed_exts = app_target.copy_files_build_phases.select do |each_phase|
#   each_phase.dst_subfolder_spec == Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:plug_ins]
# end.first

# puts 'app_embed_exts:=> ' + app_embed_exts.to_s if PanConstants.debuging

# # strip = app_target.shell_script_build_phases[1]

# shell_carthage_framework = app_target.shell_script_build_phases.reject do |block|
#   block.name.index('Carthage').nil?
# end.first
# # puts 'shell_carthage_framework:=> ' + shell_carthage_framework.to_s
# # shell_carthage_framework.input_paths.each { |a_file| puts a_file.to_s }

# app_framework_group = xcodeproj['Frameworks']
# app_project_group = xcodeproj['Projects']

# puts app_target.shell_script_build_phases.reject { |block| block.name.index('Carthage').nil? }.first.to_s if PanConstants.debuging

# app_embed_exts.clear
# # strip.input_paths.clear
# # strip.output_paths.clear
# shell_carthage_framework.input_paths.clear
# shell_carthage_framework.output_paths.clear
# # app_target.dependencies.clear

# puts cartfile_resolved if PanConstants.debuging

# cartfile_resolved.each do |key, value|
#   puts key.to_s + ' => ' + value.to_s #if PanConstants.debuging

#   name = key
#   case value[:type]
#   when 'binary'
#     framework_name = name

#     system("cd #{current_dir}; carthage bootstrap --platform iOS --new-resolver #{name};")

#     file_ref = app_framework_group.new_reference("../Carthage/Build/iOS/#{name}.framework")
#     file_ref_name = file_ref.name

#     if target_links.files.none? { |pf| pf.display_name == file_ref_name }
#       target_links.add_file_reference(file_ref)
#     end

#     # if shell_carthage_framework.files.none? { |pf| pf.display_name == file_ref_name }
#     #   shell_carthage_framework.add_file_reference(file_ref)
#     #   shell_carthage_framework.build_file(file_ref).settings = { 'ATTRIBUTES' => %w[CodeSignOnCopy RemoveHeadersOnCopy] }
#     #   strip.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/#{framework_name}.framework")

#     ipth = "#{current_dir}/Carthage/Build/iOS/#{framework_name}.framework/#{framework_name}"
#     if File.exist?(ipth)
#       fr = `file #{ipth}`
#       puts fr if PanConstants.debuging
#       if fr.include?('dynamically linked shared library')
#         shell_carthage_framework.input_paths.push("$(SRCROOT)/../Carthage/Build/iOS/#{framework_name}.framework")
#         shell_carthage_framework.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/#{framework_name}.framework")
#       end
#     end
#     # end

#   when 'git'
#     # 1, link the git bare repo with checkout directory
#     command = "git init --separate-git-dir=#{current_dir}/Carthage/Repo/#{name}.git;"
#     command += if using_sync
#                  'git reset --hard -q; git pull;'
#                else
#                  'git reset -q;'
#                end

#     system("cd #{current_dir}; carthage bootstrap --platform iOS --verbose --no-build #{name};"\
#         + "mkdir -p #{current_dir}/Carthage/Checkouts/#{name}/Carthage/ ; cd $_ ;"\
#         + "ln -s #{current_dir}/Carthage/Build . ; cd #{current_dir}/Carthage/Checkouts/#{name}/;" \
#         + command)
#     next if using_sync

#     # 2, iterator each checkouted project, and add them into Main Project's dependency

#   else
#     puts 'unknown type'
#   end
# end

puts '================================'
if !using_sync
  xcodeproj.save
  puts "Generate #{scheme_target} Xcode project success."
else
  puts "Sync #{scheme_target} success."
end
