#!/usr/bin/ruby
# frozen_string_literal: true

# XcodeBuilder builder for xcode
class XcodeBuilder
  def initialize; end

  def self.check_xcode?
    !`type xcodebuild 2> /dev/null;`.empty?
  end

  def self.xcode_build_bin
    `which xcode_build_bin`
  end

  def self.build(xcode_config)
    raise 'fatal: could not find Xcode installed in current system' unless check_xcode?
    raise 'fatal: invalid xcode project build configuration' if xcode_config.nil?

    command = xcode_build_bin.to_s
    command += " #{xcode_config.to_xc}"
    command += " #{xcode_config.to_xc_param};"

    system(command)
  end
end
