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
    until repo_framework&.is_ready || repo_framework&.framework.nil?
      repo_name = repo_framework.name.to_s
      repo_dir = "#{cli.checkout_base}/#{repo_name}/"

      # not exist? skip, find next repo to build
      unless File.exist? "#{repo_dir}"
        repo_framework = ProjectCartManager.instance.any_repo_framework
        next
      end

      # 将当前目录设置成操作目录。
      Dir.chdir("#{repo_dir}")

      xcode_project_file_path = FileUtils.find_path_in_r("#{repo_name}.xcodeproj", '.', '')
      if xcode_project_file_path.empty?
        raise "#{"***".cyan} could not find and build #{repo_name.green.bold}"
      end

      xcode_proj_file = xcode_project_file_path.first.to_s

      p_xcode_project = XcodeProject.new(xcode_proj_file.to_s,
                                         XcodeBuildConfigure::DEBUG,
                                         cli.command_line.platform)

      xc_build_result = true
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
                                            xcode_proj_file,
                                            build_scheme_name,
                                            XcodeBuildConfigure::DEBUG,
                                            "#{cli.current_dir}/Carthage/.tmp/#{repo_name}",
                                            build_dir_path.to_s,
                                            build_dir_path.to_s,
                                            cli.command_line.platform,
                                            p_xcode_project.is_swift_project?(xc_target.target_name))
        xc_config.quiet_mode = !cli.command_line.verbose
        puts '-------------------------------------------------'

        xc_build_result &&= XcodeBuilder.build_universal(xc_config, xc_target)

        unless version_hash_filepath.nil? || version_hash_filepath.empty?
          framework_cache_version = CacheVersion.new(repo_framework.framework.hash, repo_name, xc_config.framework_version_hash)
          File.write(version_hash_filepath.to_s, JSON.pretty_generate(framework_cache_version.to_json))
        end
      end

      repo_framework.is_ready = xc_build_result
      raise "fatal: error in build '#{xcode_proj_file}." unless repo_framework.is_ready

      # next one
      repo_framework = ProjectCartManager.instance.any_repo_framework
    end
  end
end
