#!/usr/bin/ruby
# frozen_string_literal: true

# XcodeBuilder builder for xcode
class XcodeBuilder
  XCODE_BUILD_EXEC = 'xcodebuild'

  def initialize; end

  def self.check_xcode?
    !`type #{XCODE_BUILD_EXEC} 2> /dev/null;`.empty?
  end

  def self.xcode_build_bin
    `which  #{XCODE_BUILD_EXEC}`.to_s.strip.freeze
  end

  def self.build(xcode_config)
    raise 'fatal: invalid xcode project build configuration' if xcode_config.nil?
    raise 'fatal: could not find Xcode installed in current system' unless check_xcode?
    raise "fatal: invalid xcode project path: '#{xcode_config.work_dir}'" unless File.exist? xcode_config.work_dir.to_s

    unless File.exist? xcode_config.derived_path.to_s
      FileUtils.mkdir_p xcode_config.derived_path.to_s
    end

    unless File.exist? xcode_config.dwarf_dSYM_path.to_s
      FileUtils.mkdir_p xcode_config.dwarf_dSYM_path.to_s
    end

    unless File.exist? xcode_config.build_output.to_s
      FileUtils.mkdir_p xcode_config.build_output.to_s
    end

    command = "cd #{xcode_config.work_dir}; "
    command += xcode_build_bin
    command += " #{xcode_config.to_xc}"
    command += " #{xcode_config.to_xc_param};"

    puts "Build command: #{command}"
    system(command)
  end
end
