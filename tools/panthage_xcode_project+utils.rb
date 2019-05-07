#!/usr/bin/ruby
#

require 'xcodeproj'

# utils about extended the XCodeProject
class XCodeProject
  def add_link_framework(target_scheme, framework_path)
    raise "fatal: target name is needed." if target_name.nil? || target_name.empty?

    found_scheme_target = target_with(target_scheme)
    raise "fatal: could not find target '#{target_scheme}'" if found_scheme_target.nil?

    framework_ref = project.frameworks_group.new_file(framework_path)
    found_scheme_target.frameworks_build_phases.add_file_reference(framework_ref)
  end

  def add_dependent_project(xc_project)

  end
end
