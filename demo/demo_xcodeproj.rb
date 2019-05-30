#!/usr/bin/ruby

require 'fileutils'
require 'xcodeproj'
require_relative '../tools/xcode_proj/models/panthage_xc_setting'
require_relative '../tools/xcode_proj/panthage_xcode_project'

xcodeproj = XcodeProject.new(FileUtils.getwd + "/sample/Panda.xcodeproj", 'Debug', XcodePlatformSDK::FOR_IOS)
puts xcodeproj.schemes.to_s
puts xcodeproj.targets.to_s

#
# all_xcode_projects = %w(panthage_base panthage_libA panthage_libB)
#
# project_dir = FileUtils.getwd + "/sample/panthage_foo/"
# xc_proj_foo = project_dir + "panthage_foo.xcodeproj"
# $cart_path = project_dir + "Carthage/"
# # xc_proj_base = xc_proj_base(all_xcode_projects[0])  # cart_path + "Checkouts/#{all_xcodeprojs[0]}/#{all_xcodeprojs[0]}.xcodeproj"
# puts xc_proj_foo
#
# target_scheme = 'panthage_foo'
#
# def xc_proj_base(name)
#   $cart_path + "Checkouts/#{name}/#{name}.xcodeproj"
# end
#
# xcodeproj = XcodeProject.new(xc_proj_foo, "#{target_scheme}", XcodePlatformSDK::FOR_IOS)
# xcodeproj.new_xcodeproj(all_xcode_projects[0].to_s, xc_proj_base(all_xcode_projects[0]).to_s, target_scheme)
# xcodeproj.new_framework(all_xcode_projects[1].to_s, xc_proj_base(all_xcode_projects[1]).to_s, target_scheme)

# xcodeproj.sort
# xcodeproj.save

