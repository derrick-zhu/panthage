#!/usr/bin/ruby
#

require_relative '../../panthage_utils'
require_relative '../../models/panthage_cmdline'
require_relative '../../xcode_proj/models/panthage_xc_scheme_model'

module CommandHelper

  def self.find_and_open_xcode_project(current_dir, config, platform)
    nil unless File.exist? current_dir

    all_file_paths = FileUtils.find_path_in_r "*.xcodeproj", current_dir, ''
    nil if all_file_paths&.empty?

    xcode_proj_path = all_file_paths.sort_by {|filename| filename.scan(/\//).count}.first

    XcodeProject.new(xcode_proj_path,
                     config,
                     platform)
  end

  def self.solve_dependency(current_dir, scheme_target, parent_name, command)
    main_project_info = CartFileBase.new(scheme_target, parent_name)

    solve_project_carthage(
        main_project_info,
        current_dir.to_s,
        scheme_target.to_s,
        current_dir.to_s,
        CommandLine.install?(command.command),
        command.using_sync,
        true
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

  def self.link_carthage_fold(cli)
    ProjectCartManager.instance.all_libraries_name.each do |fw_name|
      fw_lib = ProjectCartManager.instance.library_with_name(fw_name)
      repo_path = "#{cli.command_line.checkout_base}/#{fw_name}"
      src_bin_path = "#{cli.command_line.build_base}"

      command = "mkdir -p #{repo_path}/Carthage/Checkouts/ ; "
      command += "mkdir -p #{repo_path}/Carthage ; cd $_ ;\n"
      command += "if [ ! -d ./Build/ ] \n" \
              + "then \n" \
              + "ln -s #{src_bin_path} . \n" \
              + "fi\n"

      command += "cd #{repo_path}/Carthage/Checkouts/;"
      fw_lib.dependency.each do |lib|
        command += "if [ ! -d ./#{lib.name}/ ] \n" \
              + "then \n" \
              + "ln -s #{cli.command_line.checkout_base}/#{lib.name} . \n" \
              + "fi\n"
      end

      system(command)
    end
  end

  def self.analysis_all(cli)
    ProjectCartManager.instance.libraries.each do |_, repo|
      if repo.library.lib_type == LibType::GIT || repo.library.lib_type == LibType::GITHUB
        repo_name = repo.name.to_s
        repo_dir = "#{cli.checkout_base}/#{repo_name}"

        next unless File.exist? repo_dir.to_s
        # 将当前目录设置成操作目录.
        Dir.chdir("#{repo_dir}")
        %W(.xcodeproj .framework .a).each do |each_file|
          all_files = FileUtils.find_path_in_r("*#{each_file}", repo_dir.to_s, "#{repo_dir}/Carthage/")
          next if all_files.empty?

          # find the root level project.
          all_files = all_files.sort_by {|filename| filename.scan(/\//).count}

          target_file_path = all_files.first
          target_file_path = Pathname(target_file_path).relative_path_from(Pathname(repo_dir)).to_s

          if each_file.end_with? ".xcodeproj"
            p_xcode_proj = XcodeProject.new(target_file_path,
                                            cli.command_line.configure,
                                            cli.command_line.platform)
            p_xcode_proj.buildable_scheme_and_target.each do |buildable_st|
              repo.new_library_build_config(repo_name, target_file_path,
                                            buildable_st.scheme.dup, buildable_st.target.dup,
                                            cli.command_line.configure, cli.command_line.platform)
            end
          elsif each_file.end_with? ".a"
            dst_file_path = cli.build_base + "/#{XcodePlatformSDK::to_s(cli.command_line.platform)}/Static/" + File.basename(target_file_path)
            repo.new_library_static_config(repo_name, target_file_path, dst_file_path)
          elsif each_file.end_with? ".framework"
            dst_file_path = cli.build_base + "/#{XcodePlatformSDK::to_s(cli.command_line.platform)}/" + File.basename(target_file_path)
            repo.new_library_dynamic_config(repo_name, target_file_path, dst_file_path)
          else
            next
          end
        end
      elsif repo.library.lib_type == LibType::BINARY
        # TODO: need to be thinking about how to analysis the (3rd party) binary library
      end
    end
  end

  def self.build_all(cli)
    repo_framework = ProjectCartManager.instance.any_repo_library
    while !repo_framework&.is_ready && !repo_framework&.library.nil?
      repo_name = repo_framework.name.to_s
      repo_dir = "#{cli.checkout_base}/#{repo_name}/"

      # not exist? skip, find next repo to build
      unless File.exist? "#{repo_dir}"
        repo_framework = ProjectCartManager.instance.any_repo_library
        next
      end

      # 将当前目录设置成操作目录.
      Dir.chdir("#{repo_dir}")

      xcode_project_file_path = ''
      found_xcodeproj = false
      %W(*.xcodeproj *.framework *.a).each do |each_file_path|
        all_files = FileUtils.find_path_in_r(each_file_path, "#{repo_dir}", "#{repo_dir}/Carthage/")

        next if all_files.empty?

        all_files = all_files.sort_by {|filename| filename.scan(/\//).count} # find the root level project.

        xcode_project_file_path = all_files.first

        # absolute path -> relative path
        puts "prepare build #{xcode_project_file_path}, #{repo_dir}" if PanConstants.debugging
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

      raise "#{"***".cyan} could not find and build #{repo_name.green.bold}" if xcode_project_file_path.empty?

      if found_xcodeproj
        xcode_file = xcode_project_file_path
        xc_build_result = true
        p_xcode_project = XcodeProject.new(xcode_file.to_s,
                                           cli.command_line.configure,
                                           cli.command_line.platform)

        p_xcode_project.buildable_scheme_and_target.each do |buildable_st|

          xc_scheme = buildable_st.scheme
          xc_target = buildable_st.target

          # build_dir_path = ''
          # version_hash_filepath = ''

          if xc_target.static? or xc_target.mach_o_static?
            build_dir_path = "#{cli.current_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(xc_target.platform_type)}/Static"
            version_hash_filepath = "#{cli.current_dir}/Carthage/Build/.#{xc_target.product_name}.static.version"

          elsif xc_target.dylib?
            build_dir_path = "#{cli.current_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(xc_target.platform_type)}"
            version_hash_filepath = "#{cli.current_dir}/Carthage/Build/.#{xc_target.product_name}.dynamic.version"

          else
            next
          end

          xc_config = XcodeBuildConfigure.new("#{cli.checkout_base}/#{repo_name}",
                                              xcode_file,
                                              xc_scheme,
                                              cli.command_line.configure,
                                              "#{cli.current_dir}/Carthage/.tmp/#{repo_name}",
                                              build_dir_path.to_s,
                                              build_dir_path.to_s,
                                              cli.command_line.skip_clean,
                                              cli.command_line.platform,
                                              p_xcode_project.is_swift_project?(xc_target.target_name))
          xc_config.quiet_mode = !cli.command_line.verbose
          puts '-------------------------------------------------' if PanConstants.debugging

          xc_build_result &&= XcodeBuilder.build_universal(xc_config, xc_target)

          unless version_hash_filepath.nil? || version_hash_filepath.empty?
            framework_cache_version = CacheVersion.new(repo_framework.library.hash, repo_name, xc_config.framework_version_hash)
            File.write(version_hash_filepath.to_s, JSON.pretty_generate(framework_cache_version.to_json))
          end

          break if xc_build_result
        end

        repo_framework.is_ready = xc_build_result
        raise "fatal: error in build '#{xcode_file}." unless repo_framework.is_ready

      else
        repo_framework.is_ready = true
      end

      # next one
      repo_framework = ProjectCartManager.instance.any_repo_library
    end
  end

  def self.setup_xcodeproj(cli)
    major_xcode_proj = CommandHelper.find_and_open_xcode_project(cli.current_dir,
                                                                 cli.command_line.configure,
                                                                 cli.command_line.platform)
    raise "could not load major xcode project in #{cli.current_dir}" if major_xcode_proj.nil?

    ProjectCartManager.instance.libraries.select do |_, fw|
      fw.library.lib_type == LibType::GIT || fw.library.lib_type == LibType::GITHUB
    end.each do |_, repo_fw|
      repo_name = repo_fw.name
      repo_dir = "#{cli.checkout_base}/#{repo_name}"
      fw_scheme = repo_fw.library.scheme

      major_xcode_proj.new_xcodeproj(fw_scheme, repo_dir, cli.command_line.configure)
    end

    ProjectCartManager.instance.libraries.select do |_, fw|
      fw.library.lib_type == LibType::BINARY
    end.each do |_, bin_fw|
      # static or dylib?
      fw_name = bin_fw.name
      fw_dir = "#{cli.build_base}/#{XcodePlatformSDK::to_s(cli.command_line.platform)}/"
    end
  end
end
