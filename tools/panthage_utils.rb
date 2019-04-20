#!/usr/bin/ruby
# frozen_string_literal: true

require 'down'

require_relative 'extensions/nil_ext'
require_relative 'extensions/hash_ext'
require_relative 'panthage_dependency'
require_relative 'panthage_cartfile_model'
require_relative 'panthage_project_cart'
require_relative 'panthage_ver_helper'
require_relative 'panthage_repo_helpers'
require_relative 'panthage_downloader'

# setup_carthage_env check and setup the environments
def setup_carthage_env(current_dir)
  env_paths = Array[
      "#{current_dir}/Carthage",
      "#{current_dir}/Carthage/.tmp",
      "#{current_dir}/Carthage/Checkouts",
      "#{current_dir}/Carthage/Build",
      "#{current_dir}/Carthage/Repo"
  ]

  # mkdir if folder is NOT existed.
  env_paths.each do |each_path|
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

      meta = /((?i)binary|git|github)\s+"([^"]+)"\s+(((~>|==|>=)\s?(\d+(\.\d+)+))|("([^"]+)"))/.match(block)

      puts meta.to_s if PanConstants.debugging

      if meta && meta[1].casecmp?('git')
        f_name = %r{/([^./]+)((?i).git)?$}.match(meta[2])[1]
        cart_file_data[f_name] = CartFileGit.new(f_name, project_name,
                                                 meta[2], meta[6], meta[9], meta[5],
                                                 is_private)

      elsif meta && meta[1].casecmp?('binary')
        f_name = %r{/([^./]+)((?i).json)?$}.match(meta[2])[1]
        cart_file_data[f_name] = CartFileBinary.new(f_name, project_name,
                                                    meta[2], meta[6], meta[5],
                                                    is_private)

      elsif meta && meta[1].casecmp?('github')
        f_name = %r{([^./]+)\/([^./]+)?$}.match(meta[2])[2]
        cart_file_data[f_name] = CartFileGithub.new(f_name, project_name,
                                                    "git@github.com:#{meta[2]}.git",
                                                    meta[6], meta[9], meta[5],
                                                    is_private)

      end
    end
  end

  cart_file_data
end

# read_cart_solved_file - read the data of the solved cartfile
def read_cart_solved_file(current_dir)
  cart_file_resolved = {}

  IO.foreach("#{current_dir}/Cartfile.resolved") do |block|
    block = block.strip
    next if (block == '') || (block == "\n")

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

# solve_cart_file solve and analysis the cartfile
def solve_cart_file(current_dir, cartfile)
  # if using_carthage
  #   system "cd #{current_dir}; carthage update --no-build --no-checkout --verbose --new-resolver;"
  # else
  array_cartfile_resolve = []
  cartfile.each do |_, value|
    if value.lib_type == LibType::BINARY
      # begin
      #   uri = URI(value.url)
      #   raw = Net::HTTP.get(uri)

      #   data = JSON.parse(raw)
      #   finded = false
      #   data.sort_by { |k, _v| Gem::Version.new(k) }.reverse_each do |ver|
      #     case value.operator
      #     when '~>'
      #       ovn = to_i(ver[0])
      #       tvn = to_i(value.version)

      #       break if ovn < tvn

      #       finded = true if (ovn - tvn < (1000**3 / 10)) && (tvn >= 1000**3)
      #       finded = true if (ovn - tvn < (1000**2 / 10)) && (tvn < 1000**3)
      #     when '=='
      #       finded = true if ver[0] == value.version
      #     when '>='
      #       finded = true
      #     else
      #       raise "unknown operator #{value}"
      #     end

      #     raise "unsatisfied version for #{value}" unless finded

      #     if finded
      #       array_cartfile_resolve.push("binary \"#{value.url}\" \"#{ver[0]}\"")
      #       break
      #     end
      #   end
      # rescue StandardError => _
      #   puts "fetch Url: #{value.url}, Data: #{raw}"
      # end

    elsif value.lib_type == LibType::GIT || value.lib_type == LibType::GITHUB
      array_cartfile_resolve.push("git \"#{value.url}\" \"#{value.hash}\"")
    else
      raise "unknown type of cartfile #{value}"
    end
  end

  carfile_resolve_content = array_cartfile_resolve.sort_by { |a, _b| a }.join("\n")

  puts carfile_resolve_content.to_s if PanConstants.debugging

  unless carfile_resolve_content.empty?
    File.open("#{current_dir}/Cartfile.resolved", 'w+') do |fd|
      fd.puts carfile_resolve_content
    end
  end
end

# clone_bare_repo - clone the bare repo
def clone_bare_repo(repo_dir_base, name, value, using_install)
  puts "#{'***'.cyan} Start fetching #{name.green.bold}"
  repo_dir = "#{repo_dir_base}/#{name}.git"

  # using tag or branch ?
  if value.repo_type == GitRepoType::TAG
    git_target_head = VersionHelper.identify(value.version)
  elsif value.repo_type == GitRepoType::BRANCH
    git_target_head = value.branch
  else
    raise 'no target branch or tag?'
  end

  puts git_target_head.to_s if PanConstants.debugging

  # clone
  unless File.exist? repo_dir
    puts "#{'***'.cyan} Cloning #{name.green.bold}"
    RepoHelper.clone_bare(repo_dir_base, value.url, name, using_install, PanConstants.disable_verbose)
    puts "#{'***'.cyan} Finished!"
  end

  # fetch the commit hash value by using branch name or tags
  if value.repo_type == GitRepoType::TAG
    commit_hash = RepoHelper.clone_with_tag(
      value.url.to_s,
      name,
      git_target_head,
      repo_dir_base,
      value.compare_method,
      PanConstants.disable_verbose
    )

  elsif value.repo_type == GitRepoType::BRANCH
    print "#{'***'.cyan} "
    commit_hash = RepoHelper.clone_with_branch(
      value.url,
      name,
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

  print "#{'***'.cyan} Fetch #{name.green.bold} Done.\n\n"
end

def solve_project_carthage(current_cart_data, workspace_base_dir, scheme_target, _parent_name, current_dir, is_install, is_sync)
  raise 'fatal: invalid cartfile data, which is null' if current_cart_data.nil?

  puts ">>>>>>>>>>>>>> #{current_cart_data.name} <<<<<<<<<<<<<<<<"
  puts "Solving project: #{current_cart_data.name}, which belongs #{current_cart_data.parent_project_name}"

  cart_file_data = {}

  # analysis the Cartfile to grab workspace's basic information
  cart_file_data = merge_cart_file(cart_file_data, read_cart_file(scheme_target.to_s, "#{current_dir}/Cartfile"))
  cart_file_data = merge_cart_file(cart_file_data, read_cart_file(scheme_target.to_s, "#{current_dir}/Cartfile.private", true))

  # current_cart_data = CartFileBase.new(scheme_target, parent_name)
  # setup and sync git repo
  git_repo_for_checkout = {}

  cart_file_data.each do |new_name, new_lib|
    old_lib = ProjectCartManager.instance.framework_with_name(new_lib.name)

    if !old_lib.nil?
      ProjectCartManager.instance.verify_library_compatible(new_lib, old_lib)
      new_lib.hash = old_lib.hash
      new_lib.dependency = old_lib.dependency

      puts "#{new_lib.name} had been there.\n\tNew library: #{new_lib.description}\n\tOld library: #{old_lib.description}".bg_blue
    else
      new_lib.conflict_type == ConflictType::ACCEPT
    end

    puts new_lib.description.to_s.reverse_color

    case new_lib.conflict_type
    when ConflictType::ERROR
      raise "Halt !!! #{new_lib.error_msg}"
    when ConflictType::ACCEPT
      ProjectCartManager.instance.update_framework(new_lib)
      git_repo_for_checkout[new_name] = new_lib
    else
      # replace the old cart data, although these two data is the same
      # ProjectCartManager.instance.update_framework(new_lib)
    end

    # add each cartfile data into current_cart_data's dependency
    current_cart_data.append_raw_dependency(new_lib)
  end

  git_repo_for_checkout.select { |_, value| value.lib_type == LibType::GIT || value.lib_type == LibType::GITHUB }
                       .each do |name, value|
    clone_bare_repo("#{workspace_base_dir}/Carthage/Repo", name, value, is_install)
  end

  git_repo_for_checkout.select { |_, value| value.lib_type == LibType::BINARY }
                       .each do |name, value|
    print "#{"***".cyan} Download #{value.name.green.bold}: "
    BinaryDownloader.check_prepare_binary(value)
    print "#{value.url}\n"
    BinaryDownloader.download_binary_file(value.url, value.hash, "#{workspace_base_dir}/Carthage/.tmp/#{name}.zip")
  end

  # generate Cartfile.resolved file.
  solve_cart_file(current_dir.to_s, cart_file_data)

  git_repo_for_checkout.each do |name, value|
    if value.lib_type == LibType::BINARY
      # binary library had been checked and download previous step.
    elsif (value.lib_type == LibType::GIT) || (value.lib_type == LibType::GITHUB)
      RepoHelper.checkout_source("#{workspace_base_dir}/Carthage",
                                 value,
                                 is_sync,
                                 PanConstants.disable_verbose)
      RepoHelper.submodule_init("#{workspace_base_dir}/Carthage",
                                name.to_s)
    else
      puts "???#{value.url} -> #{value.lib_type}"
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
                           project_cart_data.name.to_s,
                           "#{workspace_base_dir}/Carthage/Checkouts/#{each_cart_data.name}",
                           is_install,
                           is_sync)

    project_cart_data.dependency.push(each_cart_data)
  end

  project_cart_data.dependency.select { |each_cart| each_cart.conflict_type == ConflictType::ACCEPT }
                   .each do |each_cart_data|
    puts "solving dependencies #{each_cart_data.name}"
    each_cart_data.conflict_type = ConflictType::IGNORE
    solve_project_dependency(each_cart_data, workspace_base_dir, is_install, is_sync)
  end
end
