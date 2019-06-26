#!/usr/bin/ruby
# frozen_string_literal: true

require 'singleton'
require_relative 'extensions/string_ext'
require_relative 'models/panthage_cartfile_model'
require_relative 'panthage_ver_helper'
require_relative 'panthage_cartfile_checker'

LibraryBuildConfig = Struct.new(:name, :project_file_path, :scheme_info, :target_info, :configure, :platform)

# FrameworkBuildTable
class LibraryInfo
  attr_reader :name,
              :library,
              :project_file_path,
              :buildable_configs
  attr_accessor :is_ready

  def initialize(name, framework)
    raise "fatal: could not create a FrameworkBuildInfo without framework body." if framework.nil?

    @name = name
    @is_ready = ((LibType::BINARY == framework.lib_type) ? true : false)
    @library = framework
    @buildable_configs = []
  end

  def project_file_path=(new_value)
    @project_file_path = new_value
  end

  def new_library_build_config(name, project_file_path, build_scheme_info, build_target_info, build_config, build_platform)
    new_lbc = LibraryBuildConfig.new(name, project_file_path, build_scheme_info, build_target_info, build_config, build_platform)
    buildable_configs.append(new_lbc)
  end

  def need_build
    return false if @library.nil?
    return false if @library.lib_type == LibType::BINARY
    return true if @library.dependency.empty?

    result = true
    @library.dependency.each do |each_lib|
      result &&= ProjectCartManager.instance.library_ready?(each_lib.name)
      break unless result
    end

    result
  end

  def description
    "Framework :#{name}, is_ready:#{is_ready}, info:#{@library.description}"
  end
end

# ProjectCartManager
class ProjectCartManager
  include Singleton

  attr_reader :libraries

  def initialize
    @libraries = Hash.new

    self.reset_all_frameworks_status
  end

  def description
    libraries.values.each_with_object([]) {|val, result| result.append(val.description)}.join "\n"
  end

  def resolved_info
    libraries.values.each_with_object([]) {|val, result| result.append(val.library&.to_resolved)}.sort!.join "\n"
  end

  def write_solved_info(file_path)
    FileUtils.remove_entry file_path if File.exist? file_path
    File.open file_path, File::RDWR | File::CREAT, 0644 do |fp|
      fp.rewind
      fp.write resolved_info
      fp.flush
      fp.truncate(fp.pos)
    end
  end

  # read_cart_solved_file - read the data of the solved cartfile
  def read_solved_info(file_path)
    nil if File.exist? file_path

    cart_file_resolved = {}
    IO.foreach(file_path.to_s) do |block|
      block = block.strip
      next if block.empty? || (block == "\n")

      meta = /((?i)binary|git|github)\s+"([^"]+)"\s+"([^"]+)"/.match(block)

      if meta
        type = meta[1]
        f_name = %r{/([^./]+)((?i).git|.json)?$}.match(meta[2])[1]
        url = meta[2]
        hash = meta[3]
      else
        puts "#{'***'.cyan} warning could not analysis #{block}"
        next
      end

      cart_file_resolved[f_name] = CartFileResolved.new_cart_solved(f_name, type, url, hash)
    end

    cart_file_resolved
  end

  def update_library(new_lib)
    raise "invalid library '#{new_lib}'" if new_lib.nil?

    libraries[new_lib.name] = LibraryInfo.new(new_lib.name, new_lib)
  end

  def library_with_name(name)
    libraries[name].library if libraries.key?(name)
  end

  def build_info_with_name(name)
    libraries[name] if libraries.key?(name)
  end

  def library_ready?(name)
    return false if libraries&.empty?
    return false unless libraries&.has_key?(name)

    #private framework is optional one, skip building.
    return true if libraries[name]&.library.is_private

    build_info_with_name(name).is_ready
  end

  def all_libraries_name
    libraries.keys
  end

  def any_repo_library
    old_idx = @idx_latest_repo

    loop do
      next_name = next_repo_name

      lib_info = @libraries[next_name]
      return lib_info if lib_info&.is_ready == false && lib_info&.need_build

      # has scanned all repo framework if idx_latest_repo step in and hit the old idx
      return nil if old_idx == @idx_latest_repo
    end
  end

  def reset_all_frameworks_status
    # just the index for the frameworks' picker
    @idx_latest_repo = 0

    unless self.libraries.nil?
      self.libraries.select do |_, raw_lib|
        raw_lib.library.lib_type == LibType::GIT || raw_lib.library.lib_type == LibType::GITHUB
      end.each do |_, raw_lib|
        raw_lib.is_ready = false
      end
    end
  end

  def verify_library_compatible(new_lib, old_lib)
    raise "could not verify library compatible between #{new_lib.name} and #{old_lib.name}" if new_lib.name != old_lib.name
    raise "incompatible library type: \n\t#{new_lib.name}(#{new_lib.parent_project_name}) -> #{new_lib.lib_type}\n and \n\t#{old_lib.name}(#{old_lib.parent_project_name}) -> #{old_lib.lib_type}" if new_lib.lib_type != old_lib.lib_type
    # raise "incompatible library repo type: \n\t#{new_lib.name}(#{new_lib.parent_project_name}) -> #{new_lib.repo_type}\n and \n\t#{old_lib.name}(#{old_lib.parent_project_name}) -> #{old_lib.repo_type}" if new_lib.repo_type != old_lib.repo_type

    CartFileChecker.check_library_by(new_lib, old_lib)
  end

  def all_repos
    @libraries.select {|_, lib| lib.library.lib_type == LibType::GIT || lib.library.lib_type == LibType::GITHUB}
  end

  private

  def next_repo_name
    result = nil
    all_repo_names = self.all_repos&.keys

    if all_repo_names&.empty?
      self.reset_all_frameworks_status
    else
      result = all_repo_names[@idx_latest_repo]
      @idx_latest_repo = (@idx_latest_repo + 1) % all_repo_names.count
    end

    result
  end

end
