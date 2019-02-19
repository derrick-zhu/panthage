#!/usr/bin/ruby

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'
require_relative 'string_colorize'
require_relative 'panthage_dependency'

g_verbose =  $DEBUGING == false ? '--quiet' : ''


raise 'wrong args usage' unless ARGV.length >= 3

# GET PARAMETER FROM OUTSIDE
exec_config = ExecuteConfig.new
exec_config.parse(ARGV)

# TODO: read for reading cartfile and cartfile.resolved
cartfile = {}
cartfile_resolved = {}

env_paths = Array[
    "#{exec_config.current_dir}/Carthage",
    "#{exec_config.current_dir}/Carthage/Checkouts",
    "#{exec_config.current_dir}/Carthage/Build",
    "#{exec_config.current_dir}/Carthage/Repo"
]

# mkdir if folder is NOT existed.
env_paths.each do |each_path|
  FileUtils.mkdir_p each_path.to_s unless File.exist? each_path.to_s
end