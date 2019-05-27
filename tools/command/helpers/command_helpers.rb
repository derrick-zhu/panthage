#!/usr/bin/ruby
#

require_relative '../../panthage_utils'
require_relative '../../models/panthage_cmdline'
require_relative '../../xcode_proj/models/panthage_xc_scheme_model'

module CommandHelper

  def self.solve_dependency(current_dir, scheme_target, parent_name, command)
    main_project_info = CartFileBase.new(scheme_target, parent_name)

    solve_project_carthage(
        main_project_info,
        current_dir.to_s,
        scheme_target.to_s,
        current_dir.to_s,
        CommandLine.install?(command.command),
        command.using_sync
    )

    puts main_project_info.to_s if PanConstants.debugging

    solve_project_dependency(
        main_project_info,
        current_dir.to_s,
        CommandLine.install?(command.command),
        command.using_sync
    )
  end

  def self.write_solved_info(file_path)
    ProjectCartManager.instance.write_solved_info(file_path)
  end

  def self.read_solved_info(file_path)
    ProjectCartManager.instance.read_solved_info(file_path.to_s)
  end

  def self.build_all(cli)
    repo_framework = ProjectCartManager.instance.any_repo_framework
    while !(repo_framework&.is_ready || repo_framework&.framework.nil?)
      repo_name = repo_framework.name.to_s
      repo_dir = "#{cli.checkout_base}/#{repo_name}/"

      # not exist? skip, find next repo to build
      unless File.exist? "#{repo_dir}"
        repo_framework = ProjectCartManager.instance.any_repo_framework
        next
      end

      # 将当前目录设置成操作目录.
      Dir.chdir("#{repo_dir}")

      xcode_project_file_path = ''
      found_xcodeproj = false
      %W(*.xcodeproj *.framework *.a).each do |each_file_path|
        all_files = FileUtils.find_path_in_r(each_file_path, "#{repo_dir}", "#{repo_dir}/Carthage/Build/")

        unless all_files.empty?
          if all_files.size == 1
            xcode_project_file_path = all_files.first
          else
            xcode_project_file_path = all_files.select do |ef|
              fpn = Pathname(ef)
              (fpn.dirname.to_s.end_with?("Carthage/Checkouts/#{repo_name}") || fpn.dirname.to_s.end_with?("Carthage/Checkouts/#{repo_name}/#{repo_name}")) &&
                  fpn.basename.to_s.include?(repo_name)
            end.first
          end

          # absolute path -> relative path
          xcode_project_file_path = Pathname(xcode_project_file_path).relative_path_from(Pathname(repo_dir)).to_s

          if "#{xcode_project_file_path}".end_with? '.xcodeproj'
            found_xcodeproj = true
            break
          elsif "#{xcode_project_file_path}".end_with?('.framework')
            found_xcodeproj = false

            dst_file_path = cli.build_base + "/#{XcodePlatformSDK::to_s(cli.command_line.platform)}/" + File.basename(xcode_project_file_path)
            %x(rm -rf '#{dst_file_path}') if File.exist? dst_file_path

            FileUtils.copy_entry "#{xcode_project_file_path}",
                                 "#{dst_file_path}",
                                 remove_destination: true
            break
          elsif "#{xcode_project_file_path}".end_with?('.a')
            found_xcodeproj = false

            dst_file_path = cli.build_base + "/#{XcodePlatformSDK::to_s(cli.command_line.platform)}/Static/" + File.basename(xcode_project_file_path)
            %x(rm -rf '#{dst_file_path}') if File.exist? dst_file_path

            FileUtils.copy_entry "#{xcode_project_file_path}",
                                 "#{dst_file_path}",
                                 remove_destination: true
            break
          end
        end
      end

      raise "#{"***".cyan} could not find and build #{repo_name.green.bold}" if xcode_project_file_path.empty?

      if found_xcodeproj
        xcode_file = xcode_project_file_path
        xc_build_result = true
        p_xcode_project = XcodeProject.new(xcode_file.to_s,
                                           XcodeBuildConfigure::DEBUG,
                                           cli.command_line.platform)

        p_xcode_project.targets.each do |xc_target|
          next if xc_target.platform_type != cli.command_line.platform

          build_dir_path = ''
          version_hash_filepath = ''
          build_scheme_name = ''

          if xc_target.static? or xc_target.mach_o_static?
            build_dir_path = "#{cli.current_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(xc_target.platform_type)}/Static"
            version_hash_filepath = "#{cli.current_dir}/Carthage/Build/.#{xc_target.product_name}.static.version"
            build_scheme_name = p_xcode_project.scheme_for_target(xc_target.target_name).name
          elsif xc_target.dylib?
            build_dir_path = "#{cli.current_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(xc_target.platform_type)}"
            version_hash_filepath = "#{cli.current_dir}/Carthage/Build/.#{xc_target.product_name}.dynamic.version"
            build_scheme_name = p_xcode_project.scheme_for_target(xc_target.target_name).name
          else
            next
          end

          xc_config = XcodeBuildConfigure.new("#{cli.checkout_base}/#{repo_name}",
                                              xcode_file,
                                              build_scheme_name,
                                              XcodeBuildConfigure::DEBUG,
                                              "#{cli.current_dir}/Carthage/.tmp/#{repo_name}",
                                              build_dir_path.to_s,
                                              build_dir_path.to_s,
                                              cli.command_line.platform,
                                              p_xcode_project.is_swift_project?(xc_target.target_name))
          xc_config.quiet_mode = !cli.command_line.verbose
          puts '-------------------------------------------------' if PanConstants.debugging

          xc_build_result &&= XcodeBuilder.build_universal(xc_config, xc_target)

          unless version_hash_filepath.nil? || version_hash_filepath.empty?
            framework_cache_version = CacheVersion.new(repo_framework.framework.hash, repo_name, xc_config.framework_version_hash)
            File.write(version_hash_filepath.to_s, JSON.pretty_generate(framework_cache_version.to_json))
          end
        end

        repo_framework.is_ready = xc_build_result
        raise "fatal: error in build '#{xcode_file}." unless repo_framework.is_ready

      else
        repo_framework.is_ready = true
      end

      # next one
      repo_framework = ProjectCartManager.instance.any_repo_framework
    end
  end
end
