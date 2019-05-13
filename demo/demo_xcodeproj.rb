#!/usr/bin/ruby

require 'fileutils'
require 'xcodeproj'

all_xcodeprojs = %w(panthage_base panthage_libA panthage_libB)

project_dir = FileUtils.getwd + "/sample/panthage_foo/"
xc_path = project_dir + "/panthage_foo.xcodeproj"
cart_path = project_dir + "/Carthage/"
puts xc_path

xcodeproj = Xcodeproj::Project.open(xc_path)

project_group = xcodeproj["Frameworks"]
project_uuids = xcodeproj.objects_by_uuid

all_xcodeprojs.each do |each_xcodeproj|
  project_group.new_reference(cart_path + "/Checkouts/#{each_xcodeproj}/#{each_xcodeproj}.xcodeproj")

  xcodeproj.root_object.project_references.each do |each_ref|
    project_group_uuid = each_ref[:product_group].uuid
    product_group_objects = (project_uuids[project_group_uuid]).children
    matched_product_obj = (product_group_objects.select do |product_obj|
      product_obj.path ==  "#{each_xcodeproj}.framework"
    end).first
    next unless matched_product_obj

    matched_product_ref = project_uuids[matched_product_obj.uuid]
    matched_product_name = matched_product_ref.path

    next
  end
end


# # xcodeproj.targets.each do | target |
# #     puts target.to_s
# # end
#
# newTarget = xcodeproj.new_target(:framework, 'Dummy1', :ios)
#
# app_target = xcodeproj.targets.find { |target| target.name == 'panthage_foo' }
# # puts xcodeproj.pretty_print.to_s
# # app_target.build_configurations.each do | config |
# #     puts config.to_s
# # end
#
# target_link = app_target.frameworks_build_phases
#
# framework_group = xcodeproj["Frameworks"]
# project_group = xcodeproj["Projects"]
#
# pFW = framework_group.new_reference("hello/hello.framework")
# target_link.add_file_reference(pFW)
#
# shell_carthage_framework = app_target.shell_script_build_phases.reject do |block|
#   block.name.index('Carthage').nil?
# end.first
#
# puts shell_carthage_framework.to_s
#
# shell_carthage_framework.input_paths.clear
# shell_carthage_framework.output_paths.clear
#
# shell_carthage_framework.input_paths.push("$(SRCROOT)/../Carthage/Build/iOS/hello.framework")
# shell_carthage_framework.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/hello.framework")


xcodeproj.sort
xcodeproj.save
