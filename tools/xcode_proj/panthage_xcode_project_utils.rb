#!/usr/bin/ruby

require 'xcodeproj'

class XcodeProject
  def new_xcodeproj(xcodeproj_scheme, xcodeproj_path, to_target)
    raise "fatal: invalid xcode scheme: #{xcodeproj_scheme} or path: #{xcodeproj_path}" if xcodeproj_scheme.empty? || xcodeproj_path.empty?
    raise "fatal: invalid xcode project path: #{xcodeproj_path}" unless File.exist? xcodeproj_path

    xc_target = self.project.targets.find {|tt| tt.name == to_target}
    xc_link = xc_target.frameworks_build_phases
    xc_embed = embed_framework_of_target(xc_target)
    xc_script = shell_script_build_phase_with(xc_target, 'Carthage Embed Frameworks', true)
    xc_fw_group = self.project["Frameworks"]
    xc_uuids = self.project.objects_by_uuid

    unless xc_fw_group.find_file_by_path(xcodeproj_path)
      xc_fw_group.new_reference(xcodeproj_path)
    end

    self.project.root_object.project_references.each do |each_ref|
      uuid = each_ref[:product_group].uuid
      uuid_objects = (xc_uuids[uuid]).children
      match_uuid_obj = uuid_objects.find {|each_uuid_obj| each_uuid_obj.path == "#{xcodeproj_scheme}.framework"}
      next unless match_uuid_obj

      match_uuid_obj_ref = xc_uuids[match_uuid_obj.uuid]
      match_uuid_obj_ref_name = match_uuid_obj_ref.path

      if xc_link.files.none? {|file_name| file_name.display_name == match_uuid_obj_ref_name}
        xc_link.add_file_reference(match_uuid_obj_ref)
      end

      next unless xc_embed.files.none? {|file_name| file_name.display_name == match_uuid_obj_ref_name}

      xc_embed.add_file_reference(match_uuid_obj_ref)
      xc_embed.build_file(match_uuid_obj_ref).settings = {'ATTRIBUTES' => %w[CodeSignOnCopy RemoveHeadersOnCopy]}
      xc_script.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/#{xcodeproj_scheme}.framework")
    end

    sub_project = Xcodeproj::Project.open(xcodeproj_path.to_s)
    matched_target = sub_project.targets.find {|et| et.name == xcodeproj_scheme}
    nil unless matched_target

    xc_target.add_dependency(matched_target)
  end

  def new_framework(framework_name, framework_path, to_target)
    raise "fatal: invalid framework name parameter with a nil or a empty value." if framework_name.nil? || framework_name.empty?
    raise "fatal: invalid file path of the framework: #{framework_path}" if framework_path.nil? || framework_path&.empty? || !File.exist?(framework_path)

    xc_target = self.project.targets.find {|tt| tt.name == to_target}
    xc_link = xc_target.frameworks_build_phases
    xc_embed = embed_framework_of_target(xc_target)
    xc_script = shell_script_build_phase_with(xc_target, 'Carthage Embed Frameworks', true)
    xc_fw_group = self.project["Frameworks"]

    fw_ref = xc_fw_group.new_reference("../Carthage/Build/#{XcodePlatformSDK.to_s(self.platform)}/#{framework_name}.framework")
    fw_ref_name = fw_ref.name

    if xc_link.files.none? {|pf| pf.display_name == fw_ref_name}
      xc_link.add_file_reference(fw_ref)
    end

    if xc_embed.files.none? {|pf| pf.display_name == fw_ref_name}
      xc_embed.add_file_reference fw_ref
      xc_embed.build_file(fw_ref).settings = {'ATTRIBUTES' => %w[CodeSignOnCopy RemoveHeadersOnCopy]}
      xc_script.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/#{framework_name}.framework")

      fw_bin_path = "../Carthage/Build/#{XcodePlatformSDK.to_s(self.platform)}/#{framework_name}.framework"
      if File.exists? fw_bin_path
        fw_bin_info = `file #{fw_bin_path}`
        if fw_bin_info.include? 'dynamically linked shared library'
          xc_script.input_paths.push("$(SRCROOT)/../Carthage/Build/#{XcodePlatformSDK.to_s(self.platform)}/#{framework_name}.framework")
          xc_script.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/#{framework_name}.framework")
        end
      end
    end

  end

  def is_swift_project?(target_name)
    target = self.project.targets.find {|et| et.display_name == target_name}
    nil if target.nil?
    has_swift? target
  end

  private

  def shell_script_build_phase_with(target, name, force_create = false)
    return nil if target.nil?
    return nil if name.nil? || name.empty?

    result = target.shell_script_build_phases.find {|bp| bp.name == name}
    if result.nil? && force_create
      result = target.new_shell_script_build_phase(name)
      result.shell_path = '/bin/sh'
      result.shell_script = '/usr/local/bin/carthage copy-frameworks'
    end

    result
  end

  def embed_framework_of_target(target)
    return nil if target.nil?
    target.copy_files_build_phases.find {|bp| bp.name == 'Embed Frameworks'}
  end

  def has_swift?(target)
    nil if target.nil?
    target&.source_build_phase.files.to_a.map do |raw_src_file|
      raw_src_file.file_ref.real_path.to_s
    end.select do |src_file|
      src_file.end_with?(".swift")
    end.select do |swift_file|
      File.exists? swift_file
    end.count > 0
  end
end
