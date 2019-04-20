#!/usr/bin/ruby

class XcodeProjectHelper
  attr_reader :xcode_project,
              :project

  def initialize(xcode_project)
    @xcode_project = xcode_project
    @project = Xcodeproj::Project.open(xcode_project.to_s)
  end

  def save_xcode_project
    project.save
  end

  def add_link_framework(target_scheme, framework_path)
    found_scheme_target = target_with(target_scheme)
    raise "fatal: could not find target '#{target_scheme}'" if found_scheme_target.nil?

    framework_ref = project.frameworks_group.new_file(framework_path)
    found_scheme_target.frameworks_build_phases.add_file_reference(framework_ref)
  end

  private

  def target_with(scheme)
    raise "fatal: invalid XcodeProj instance for #{xcode_project}" if project.nil?

    project.targets.each_with_index do |each_scheme, idx|
      if each_scheme.name == scheme
        return project.targets[idx]
      end
    end
  end


end
