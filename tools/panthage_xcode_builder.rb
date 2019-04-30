#!/usr/bin/ruby
# frozen_string_literal: true

require 'digest'

# XcodeBuilder builder for xcode
class XcodeBuilder
  LIPO_EXEC = 'lipo'
  XCRUN_EXEC = 'xcrun'
  XCODE_BUILD_EXEC = 'xcodebuild'

  def initialize;
  end

  # @param [XcodeBuildConfigure] xcode_config
  # @return [Bool] YES if every thing is fine.
  def self.build_universal(xcode_config)
    raise 'fatal: could not find Xcode installed in current system' unless check_xcrun? && check_lipo?

    result = true

    # check and build temporary universal dir
    universal_path = "#{xcode_config.derived_path}/#{xcode_config.configuration}_universal"
    FileUtils.mkdir_p universal_path.to_s unless File.exist? universal_path.to_s

    # build the iphone and the iphone simulator arch library
    XcodeSDKRoot.sdk_root(xcode_config.platform_sdk)
        .each do |sdk|
      xcode_config.sdk = sdk
      result &&= build(xcode_config)
    end

    raise 'fatal: fails in build xcodeproj' unless result

    # copy the to universal folder
    if File.exist? "#{universal_path}/#{xcode_config.scheme}.framework"
      FileUtils.remove_entry "#{universal_path}/#{xcode_config.scheme}.framework",
                             force: true
    end
    # 1, let iphoneos library as base one.
    FileUtils.copy_entry "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONEOS}/#{xcode_config.scheme}.framework",
                         "#{universal_path}/#{xcode_config.scheme}.framework",
                         remove_destination: true

    # 2, let iphone simulator library as ext one
    FileUtils.copy_entry "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONE_SIMULATOR}/#{xcode_config.scheme}.framework/Modules/#{xcode_config.scheme}.swiftmodule",
                         "#{universal_path}/#{xcode_config.scheme}.framework/Modules/#{xcode_config.scheme}.swiftmodule",
                         remove_destination: true

    # create universal binary file by using `lipo`
    result &&= system([
                          "#{xcrun_bin} #{lipo_bin}",
                          '-create',
                          "-output #{universal_path}/#{xcode_config.scheme}.framework/#{xcode_config.scheme}",
                          "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONE_SIMULATOR}/#{xcode_config.scheme}.framework/#{xcode_config.scheme}",
                          "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONEOS}/#{xcode_config.scheme}.framework/#{xcode_config.scheme}"
                      ].join(' '))

    raise 'fatal: fails in create universal library' unless result

    # copy universal one into universal folder
    FileUtils.copy_entry "#{universal_path}/#{xcode_config.scheme}.framework",
                         "#{xcode_config.build_output}/#{xcode_config.scheme}.framework",
                         remove_destination: true

    # clear the env
    FileUtils.remove_entry "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONE_SIMULATOR}", force: true
    FileUtils.remove_entry "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONEOS}", force: true

    # save the SHA256 hash value.
    xcode_config.framework_version_hash = generate_digest(xcode_config)

    result
  end

  private_class_method def self.check_lipo?
                         !`type #{LIPO_EXEC} 2> /dev/null;`.empty?
                       end

  private_class_method def self.lipo_bin
                         `which #{LIPO_EXEC}`.to_s.strip.freeze
                       end

  private_class_method def self.check_xcrun?
                         !`type #{XCRUN_EXEC} 2> /dev/null;`.empty?
                       end

  private_class_method def self.xcrun_bin
                         `which #{XCRUN_EXEC}`.to_s.strip.freeze
                       end

  private_class_method def self.check_xcode?
                         !`type #{XCODE_BUILD_EXEC} 2> /dev/null;`.empty?
                       end

  private_class_method def self.xcode_build_bin
                         `which  #{XCODE_BUILD_EXEC}`.to_s.strip.freeze
                       end

  private_class_method def self.build(xcode_config)
                         raise 'fatal: invalid xcode project build configuration' if xcode_config.nil?
                         raise 'fatal: could not find Xcode installed in current system' unless check_xcode? && check_xcrun?
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

                         command = [
                             "cd #{xcode_config.work_dir};",
                             "#{xcrun_bin} #{xcode_build_bin}",
                             "#{xcode_config.to_xc}",
                             "#{xcode_config.to_xc_param}",
                             "#{xcode_config.to_xc_ext_param}"
                         ]
                         command.push("2> /dev/null ;") if xcode_config.quiet_mode
                         command = command.join(' ')

                         puts "Build command: #{command}"
                         system(command)
                       end

  private_class_method def self.generate_digest(xcode_config)
                         raise 'fatal: invalid xcode project build configuration' if xcode_config.nil?

                         bin_path = "#{xcode_config.build_output}/#{xcode_config.scheme}.framework/#{xcode_config.scheme}"
                         bin_data = File.read(bin_path.to_s)
                         Digest::SHA2.new(256).hexdigest(bin_data)
                       end
end
