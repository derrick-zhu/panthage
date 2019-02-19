#!/usr/bin/ruby

require 'fileutils'
require 'xcodeproj'

file_path = FileUtils.getwd + "/Panda.xcodeproj"
puts file_path

xcodeproj = Xcodeproj::Project.open(file_path)

# xcodeproj.targets.each do | target |
#     puts target.to_s
# end

newTarget = xcodeproj.new_target(:framework, 'Dummy1', :ios)

app_target = xcodeproj.targets.find { |target| target.name == 'Panda' }
# puts xcodeproj.pretty_print.to_s
# app_target.build_configurations.each do | config |
#     puts config.to_s
# end

target_link = app_target.frameworks_build_phases

framework_group = xcodeproj["Frameworks"]
project_group = xcodeproj["Projects"]

pFW = framework_group.new_reference("hello/hello.framework")
target_link.add_file_reference(pFW)

shell_carthage_framework = app_target.shell_script_build_phases.reject do |block|
  block.name.index('Carthage').nil?
end.first

puts shell_carthage_framework.to_s

shell_carthage_framework.input_paths.clear
shell_carthage_framework.output_paths.clear

shell_carthage_framework.input_paths.push("$(SRCROOT)/../Carthage/Build/iOS/hello.framework")
shell_carthage_framework.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/hello.framework")


xcodeproj.sort
xcodeproj.save
