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
  def self.build_universal(xcode_config, target_config)
    raise 'fatal: could not find Xcode installed in current system' unless check_xcrun? && check_lipo?
    puts "#{'***'.cyan} building #{xcode_config.scheme}"

    result = true
    # check and build temporary universal dir
    universal_path = "#{xcode_config.derived_path}/#{xcode_config.configuration}_universal"

    # clear the old temp binary fold before lipo
    XcodeSDKRoot.sdk_root(xcode_config.platform_sdk).each do |sdk|
      output_for_sdk = "#{xcode_config.build_output}/#{xcode_config.configuration}_#{sdk}"
      FileUtils.remove_entry output_for_sdk if File.exist? output_for_sdk
      FileUtils.mkdir_p output_for_sdk
    end
    FileUtils.mkdir_p universal_path.to_s unless File.exist? universal_path.to_s
    FileUtils.remove_entry "#{universal_path}/#{xcode_config.app_name}", force: true if File.exist? "#{universal_path}/#{xcode_config.app_name}"

    # build the iphone and the iphone simulator arch library
    XcodeSDKRoot.sdk_root(xcode_config.platform_sdk)
        .each do |sdk|
      output_for_sdk = "#{xcode_config.build_output}/#{xcode_config.configuration}_#{sdk}"
      old_binary = "#{xcode_config.build_output}/#{xcode_config.app_name}"
      FileUtils.remove_entry old_binary, force: true if File.exists? old_binary

      xcode_config.sdk = sdk
      result &&= build(xcode_config)

      FileUtils.copy_entry("#{xcode_config.build_output}/#{xcode_config.app_name}",
                           "#{output_for_sdk}/#{xcode_config.app_name}",
                           remove_destination: true) if result
    end

    raise 'fatal: fails in build xcodeproj' unless result

    if target_config.static?
      # copy the to universal folder
      if File.exist? "#{universal_path}/#{xcode_config.app_name}"
        FileUtils.remove_entry "#{universal_path}/#{xcode_config.app_name}", force: true
      end

      lipo_command = ["#{xcrun_bin} #{lipo_bin}",
                      '-create',
                      "-output '#{universal_path}/#{xcode_config.app_name}'",
                      "'#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONE_SIMULATOR}/#{xcode_config.app_name}'",
                      "'#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONEOS}/#{xcode_config.app_name}'"
      ].join(' ')
      puts "LIPO command: #{lipo_command}" if PanConstants.debugging
      result &&= system(lipo_command)

      raise 'fatal: fails in create universal library' unless result

      # copy universal static library
      FileUtils.copy_entry "#{universal_path}/#{xcode_config.app_name}",
                           "#{xcode_config.build_output}/#{xcode_config.app_name}",
                           remove_destination: true

      # copy header files
      FileUtils.copy_entry "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONEOS}/include",
                           "#{xcode_config.build_output}/include",
                           remove_desination: true

    elsif target_config.dylib?
      # let iphoneos library as base one.
      FileUtils.copy_entry "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONEOS}/#{xcode_config.app_name}",
                           "#{universal_path}/#{xcode_config.app_name}",
                           remove_destination: true

      # let iphone simulator library as ext one
      if xcode_config.is_swift_project
        FileUtils.copy_entry "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONE_SIMULATOR}/#{xcode_config.app_name}/Modules/#{xcode_config.app_product_name}.swiftmodule",
                             "#{universal_path}/#{xcode_config.app_name}/Modules/#{xcode_config.app_product_name}.swiftmodule",
                             remove_destination: true
      end

      # create universal binary file by using `lipo`
      result &&= system(
          ["#{xcrun_bin} #{lipo_bin}",
           '-create',
           "-output #{universal_path}/#{xcode_config.app_name}/#{xcode_config.app_product_name}",
           "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONE_SIMULATOR}/#{xcode_config.app_name}/#{xcode_config.app_product_name}",
           "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONEOS}/#{xcode_config.app_name}/#{xcode_config.app_product_name}"
          ].join(' ')
      )

      # header
      if xcode_config.is_swift_project
        fat_header_path = "#{universal_path}/#{xcode_config.app_name}/Headers/#{xcode_config.app_product_name}-Swift.h"
        FileUtils.remove_entry fat_header_path if File.exist? fat_header_path

        fat_header = "#ifndef TARGET_OS_SIMULATOR\n"  \
            "#include <TargetConditionals.h>\n" \
            "#endif\n"  \
            "#if TARGET_OS_SIMULATOR\n"
        fat_header += File.read("#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONE_SIMULATOR}/#{xcode_config.app_name}/Headers/#{xcode_config.app_product_name}-Swift.h")
        fat_header += "\n#else\n"
        fat_header += File.read("#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONEOS}/#{xcode_config.app_name}/Headers/#{xcode_config.app_product_name}-Swift.h")
        fat_header += "\n#endif\n"

        File.open("#{fat_header_path}", File::WRONLY|File::CREAT, 0644) do |fp|
          fp.rewind
          fp.write(fat_header)
          fp.flush
          fp.close
        end

      end


      raise 'fatal: fails in create universal library' unless result

      # copy universal one into universal folder
      FileUtils.copy_entry "#{universal_path}/#{xcode_config.app_name}",
                           "#{xcode_config.build_output}/#{xcode_config.app_name}",
                           remove_destination: true
    end

    # clear the env
    FileUtils.remove_entry "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONE_SIMULATOR}", force: true
    FileUtils.remove_entry "#{xcode_config.build_output}/#{xcode_config.configuration}_#{XcodeSDKRoot::SDK_IPHONEOS}", force: true

    # save the SHA256 hash value.
    xcode_config.framework_version_hash = generate_digest(xcode_config, target_config)

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
                             "#{xcode_config.to_xc_ext_param}",
                             "#{CommandLine.instance.verbose_flag};"
                         ].join(' ')

                         puts "build command: #{command}" if PanConstants.debugging
                         system(command)
                       end

  private_class_method def self.generate_digest(xcode_config, target_config)
                         raise 'fatal: invalid xcode project build configuration' if xcode_config.nil? || target_config.nil?

                         bin_path = ''
                         if target_config.dylib?
                           bin_path = "#{xcode_config.build_output}/#{xcode_config.app_name}/#{xcode_config.app_product_name}"
                         elsif target_config.static?
                           bin_path = "#{xcode_config.build_output}/#{xcode_config.app_name}"
                         else
                           raise "fatal: could not generate digest for #{bin_path}"
                         end

                         unless bin_path.empty?
                           bin_data = File.read(bin_path.to_s)
                           Digest::SHA2.new(256).hexdigest(bin_data)
                         end
                       end
end
