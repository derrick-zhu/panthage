#!/usr/bin/ruby
# frozen_string_literal: true

require 'down'

require_relative 'extensions/nil_ext'
require_relative 'extensions/hash_ext'
require_relative 'panthage_dependency'
require_relative 'models/panthage_cartfile_model'
require_relative 'panthage_cart_manager'
require_relative 'panthage_ver_helper'
require_relative 'panthage_repo_helpers'
require_relative 'panthage_downloader'
require_relative 'xcode_proj/panthage_xcode_project'

# setup_carthage_env check and setup the environments
def setup_carthage_env(current_dir)
  # mkdir if folder is NOT existed.
  %W(#{current_dir}/Carthage #{current_dir}/Carthage/.tmp #{current_dir}/Carthage/Checkouts #{current_dir}/Carthage/Build #{current_dir}/Carthage/Repo).each do |each_path|
    FileUtils.mkdir_p each_path.to_s unless File.exist? each_path.to_s
  end
end

# merge new libraries hash into the old library hash, here we need compare them with the tag version, branch information
# Params:
# +old_cart:: the collection of the old libraries in hash
# +new_cart:: the collection of the newer libraries needs to be added.
def merge_cart_file(old_cart, new_cart)
  need_added_data = {}

  new_cart.each do |new_name, new_data|
    if old_cart.key?(new_name)
      old_data = old_cart[new_name]

      new_data = CartFileChecker.check_library_by(new_data, old_data)

      case new_data.conflict_type
      when ConflictType::ACCEPT
        need_added_data[new_name] = new_data
      when ConflictType::ERROR
        raise "Halt !!! #{new_data.error_msg}"
      else
        # ignore state, do nothing.
      end

    else # not has key 'new_name'
      new_data.conflict_type = ConflictType::ACCEPT
      need_added_data[new_name] = new_data
    end
  end

  old_cart.merge!(need_added_data)
  old_cart
end

# read_cart_file Reading data from cartfile
def read_cart_file(project_name, cart_file, is_private = false)
  cart_file_data = {}

  if File.exist? cart_file
    IO.foreach(cart_file) do |block|
      block = block.strip
      next if (block == '') || (block[0] == "\#")

      meta = /((?i)binary|git|github)\s+"([^"]+)"\s+(~>|==|>=)?\s?"?([\w\/.-]+)"?/.match(block)

      puts meta.to_s if PanConstants.debugging

      if meta && meta[1].casecmp?('git')
        f_name = %r{/([^./]+)((?i).git)?$}.match(meta[2])[1]

        compare_method = meta[3]
        tag = (compare_method.nil? || compare_method.empty?) ? nil : meta[4]
        branch = (!compare_method.nil? && !compare_method.empty?) ? nil : meta[4]

        cart_file_data[f_name] = CartFileGit.new(f_name, project_name,
                                                 meta[2], tag, branch,
                                                 compare_method, is_private)

      elsif meta && meta[1].casecmp?('github')
        f_name = %r{([^./]+)\/([^./]+)?$}.match(meta[2])[2]

        compare_method = meta[3]
        tag = (compare_method.nil? || compare_method.empty?) ? nil : meta[4]
        branch = (!compare_method.nil? && !compare_method.empty?) ? nil : meta[4]

        cart_file_data[f_name] = CartFileGithub.new(f_name, project_name,
                                                    "git@github.com:#{meta[2]}.git",
                                                    tag, branch, compare_method,
                                                    is_private)

      elsif meta && meta[1].casecmp?('binary')
        f_name = %r{/([^./]+)((?i).json)?$}.match(meta[2])[1]
        tag = meta[4]
        compare_method = meta[3]
        cart_file_data[f_name] = CartFileBinary.new(f_name, project_name,
                                                    meta[2], tag, compare_method,
                                                    is_private)

      end
    end
  end

  cart_file_data
end

# clone_bare_repo - clone the bare repo
def clone_bare_repo(repo_dir_base, repo_name, value, using_install)
  puts "#{'***'.cyan} fetching #{repo_name.green.bold}"
  repo_dir = "#{repo_dir_base}/#{repo_name}.git"

  # using tag or branch ?
  if value.repo_type == GitRepoType::TAG
    git_target_head = VersionHelper.identify(value.version)
  elsif value.repo_type == GitRepoType::BRANCH
    git_target_head = value.branch
  else
    raise 'no target branch or tag?'
  end

  # check current repo had been cloned or not.
  if File.exist? repo_dir

    # check current git repo's status
    if RepoHelper.is_status?(repo_dir, git_target_head)
      case value.repo_type
      when GitRepoType::TAG
        value.hash = RepoHelper.current_status(repo_dir)
      when GitRepoType::BRANCH
        value.hash = RepoHelper.current_hash(repo_dir)
      else
        raise 'no target branch or tag?'
      end

      return
    end
  else
    # clone
    puts "#{'***'.cyan} Cloning #{repo_name.green.bold}"
    RepoHelper.clone_bare(repo_dir_base, value.url, repo_name, using_install, PanConstants.disable_verbose)
  end

  RepoHelper.reset_repo_config(repo_dir_base, repo_name, value.url)

  # fetch the commit hash value by using branch name or tags
  if value.repo_type == GitRepoType::TAG
    commit_hash = RepoHelper.clone_with_tag(
        repo_name,
        git_target_head,
        repo_dir_base,
        value.compare_method,
        PanConstants.disable_verbose
    )

  elsif value.repo_type == GitRepoType::BRANCH
    commit_hash = RepoHelper.clone_with_branch(
        repo_name,
        git_target_head,
        repo_dir_base,
        using_install,
        PanConstants.disable_verbose
    )
  else
    raise "unknown repo type #{value.repo_type}"
  end

  raise "unknown branch or tag or commit #{value} and commit hash:#{commit_hash}." if value.repo_type == GitRepoType::BRANCH && commit_hash.length != 40
  raise "unknown branch or tag or commit #{value} and commit hash:#{commit_hash}." if value.repo_type == GitRepoType::TAG && commit_hash.empty?

  # save the commit's SHA1 hash.
  value.hash = commit_hash.strip.freeze

  # print "#{'***'.cyan} Fetch #{name.green.bold} Done.\n\n"
end

def load_cart_file(current_dir, scheme_target, need_private = false)
  cart_file_data = {}

  cart_file_data = merge_cart_file(cart_file_data, read_cart_file(scheme_target.to_s, "#{current_dir}/Cartfile"))
  cart_file_data = merge_cart_file(cart_file_data, read_cart_file(scheme_target.to_s, "#{current_dir}/Cartfile.private", true)) if need_private

  cart_file_data
end

def solve_project_carthage(current_cart_data, workspace_base_dir, scheme_target, current_dir, is_install, is_sync, is_main = false)
  raise 'fatal: invalid cartfile data, which is null' if current_cart_data.nil?

  puts ">>>>>>>>>>>>>> #{current_cart_data.name} <<<<<<<<<<<<<<<<" if PanConstants.debugging
  puts "Solving project: #{current_cart_data.name}, which belongs #{current_cart_data.parent_project_name}" if PanConstants.debugging

  # analysis the Cartfile to grab workspace's basic information
  cart_file_data = load_cart_file(current_dir, scheme_target, is_main)

  # setup and sync git repo
  git_repo_for_checkout = {}

  cart_file_data.each do |new_name, new_lib|
    old_lib = ProjectCartManager.instance.library_with_name(new_lib.name)

    if !old_lib.nil?
      ProjectCartManager.instance.verify_library_compatible(new_lib, old_lib)
      if new_lib.conflict_type != ConflictType::IGNORE
        puts "#{new_lib.name} had been there.\n\tNew library: #{new_lib.description}\n\tOld library: #{old_lib.description}".bg_blue if PanConstants.debugging
      end
    else
      new_lib.conflict_type == ConflictType::ACCEPT
    end

    puts new_lib.description.to_s.reverse_color if PanConstants.debugging

    case new_lib.conflict_type
    when ConflictType::ERROR
      raise "Halt !!! #{new_lib.error_msg}"
    when ConflictType::ACCEPT
      ProjectCartManager.instance.update_library(new_lib)
      git_repo_for_checkout[new_name] = new_lib
    else
      # ignore?
    end

    # add each cartfile data into current_cart_data's dependency
    current_cart_data.append_raw_dependency(new_lib)
  end

  git_repo_for_checkout.each do |name, value|
    case value.lib_type
    when LibType::GIT, LibType::GITHUB
      clone_bare_repo("#{workspace_base_dir}/Carthage/Repo", name, value, is_install)

    when LibType::BINARY
      print "#{"***".cyan} Download #{value.name.green.bold}: "
      BinaryDownloader.check_prepare_binary(value)
      puts "#{value.url}\n" if PanConstants.debugging

      target_zip_file = "#{workspace_base_dir}/Carthage/.tmp/#{name}.zip"
      BinaryDownloader.download_binary_file(value.url, value.hash, target_zip_file)

      BinaryDownloader.unzip(target_zip_file, "*.framework", "#{workspace_base_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(CommandLine.instance.platform)}/") ||
          BinaryDownloader.unzip(target_zip_file, "*.a", "#{workspace_base_dir}/Carthage/Build/#{XcodePlatformSDK::to_s(CommandLine.instance.platform)}/")

    else
      # empty
    end
  end

  git_repo_for_checkout.each do |repo_name, repo_data|
    if repo_data.lib_type == LibType::BINARY
      # binary library had been checked and download previous step.
    elsif (repo_data.lib_type == LibType::GIT) || (repo_data.lib_type == LibType::GITHUB)
      RepoHelper.checkout_source("#{workspace_base_dir}/Carthage",
                                 repo_data,
                                 is_sync,
                                 PanConstants.disable_verbose)
      RepoHelper.submodule_init("#{workspace_base_dir}/Carthage",
                                repo_name.to_s)
    else
      puts "???#{repo_data.url} -> #{repo_data.lib_type}"
    end
  end
end

# solve_project_dependency
def solve_project_dependency(project_cart_data, workspace_base_dir, is_install, is_sync)
  return if project_cart_data.nil?
  return unless project_cart_data.dependency.empty?

  project_cart_data.raw_dependency.each do |each_cart_data|
    solve_project_carthage(each_cart_data,
                           workspace_base_dir.to_s,
                           each_cart_data.name.to_s,
                           "#{workspace_base_dir}/Carthage/Checkouts/#{each_cart_data.name}",
                           is_install,
                           is_sync,
                           false)

    project_cart_data.dependency.push(each_cart_data)
  end

  project_cart_data.dependency.select {|each_cart| each_cart.conflict_type == ConflictType::ACCEPT}
      .each do |each_cart_data|
    puts "solving dependencies #{each_cart_data.name}" if PanConstants.debugging
    each_cart_data.conflict_type = ConflictType::IGNORE
    solve_project_dependency(each_cart_data, workspace_base_dir, is_install, is_sync)
  end
end
