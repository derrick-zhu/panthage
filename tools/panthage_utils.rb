#!/usr/bin/ruby
# frozen_string_literal: true

require 'down'

require_relative 'common_ext'
require_relative 'panthage_dependency'
require_relative 'panthage_cartfile_model'
require_relative 'panthage_project_cart'
require_relative 'panthage_ver_helper'
require_relative 'panthage_repo_helpers'

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

      new_data = CartfileChecker.check_library_by(new_data, old_data)

      case new_data.conflict_type
      when ConflictType::ACCEPT
        need_added_data[new_name] = new_data
      when ConflictType::ERROR
        raise "Halt !!! #{new_data.error_msg}"
      end

    else # not has key 'new_name'
      new_data.conflict_type = ConflictType::ACCEPT
      need_added_data[new_name] = new_data
    end
  end

  old_cart.merge!(need_added_data)
  old_cart
end

def show_conflict_tag(new_data, old_data)
  "conflict framework version:\n\t#{new_data.version} by #{new_data.proj_name}\tand\n\t#{old_data.version} by #{old_data.proj_name}"
end

def show_conflict_branch(new_data, old_data)
  "conflict framework version:\n\t#{new_data.branch} by #{new_data.proj_name}\tand\n\t#{old_data.branch} by #{old_data.proj_name}"
end

# read_cart_file Reading data from cartfile
def read_cart_file(proj_name, cart_file)
  cartFileData = {}

  if File.exist? cart_file
    IO.foreach(cart_file) do |block|
      block = block.strip
      next if (block == '') || (block[0] == "\#")

      meta = /((?i)binary|git|github)\s+"([^"]+)"\s+(((~>|==|>=)\s?(\d+(\.\d+)+))|("([^"]+)"))/.match(block)

      puts meta.to_s if PanConstants.debuging

      if meta && meta[1].casecmp?('git')
        f_name = %r{/([^./]+)((?i).git)?$}.match(meta[2])[1]
        cartFileData[f_name] = CartfileGit.new(f_name, proj_name, meta[2], meta[6], meta[9], meta[5])\
      elsif meta && meta[1].casecmp?('binary')
        f_name = %r{/([^./]+)((?i).json)?$}.match(meta[2])[1]
        cartFileData[f_name] = CartfileBinary.new(f_name, proj_name, meta[2], meta[6], meta[5])
      elsif meta && meta[1].casecmp?('github')
        f_name = %r{([^./]+)\/([^./]+)?$}.match(meta[2])[2]
        cartFileData[f_name] = CartfileGithub.new(f_name, proj_name, "git@github.com:#{meta[2]}.git", meta[6], meta[9], meta[5])
      end
    end
  end

  cartFileData
end

# read_cart_solved_file - read the data of the solved cartfile
def read_cart_solved_file(current_dir)
  cartfile_resolved = {}

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

    cartfile_resolved[f_name] = CartfileResolved.new_cart_solved(f_name, type, url, hash)
  end

  cartfile_resolved
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
      #       raise "unknow operator #{value}"
      #     end

      #     raise "unstatisfied version for #{value}" unless finded

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

  puts carfile_resolve_content.to_s if PanConstants.debuging

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
  git_target_head = ''

  puts value.to_s if PanConstants.debuging

  # using tag or branch ?
  if value.repo_type == GitRepoType::TAG
    puts 'its tag' if PanConstants.debuging
    git_target_head = VersionHelper.identify(value.version)
  elsif value.repo_type == GitRepoType::BRANCH
    puts 'its branch' if PanConstants.debuging
    git_target_head = value.branch
  else
    raise 'no target branch or tag?'
  end

  puts git_target_head.to_s if PanConstants.debuging

  # clone
  unless File.exist? repo_dir
    puts "#{'***'.cyan} Cloning #{name.green.bold}"

    RepoHelper.clone_bare(repo_dir_base, value.url, name, using_install, PanConstants.disable_verbose)

    puts "#{'***'.cyan} Finished!"
  end

  # fetch the commit hash value by using branch name or tags
  if value.repo_type == GitRepoType::TAG
    commit_hash = RepoHelper.clone_with_tag(
      value.url,
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

  end

  raise "unknow branch or tag or commit #{value} and commit hash:#{commit_hash}." if value.repo_type == GitRepoType::BRANCH && commit_hash.length != 40
  raise "unknow branch or tag or commit #{value} and commit hash:#{commit_hash}." if value.repo_type == GitRepoType::TAG && commit_hash.empty?

  # save the commit's SHA1 hash.
  value.hash = commit_hash.strip.freeze

  print "#{'***'.cyan} Fetch #{name.green.bold} Done.\n\n"
end

def check_prepare_binary(value)
  info_file = Down.download(value.url)
  info_raw = info_file.read
  info_data = JSON.parse(info_raw)

  binary_list = VersionHelper.find_fit_version(info_data.keys, value.version, value.operator)
  raise "could not find #{value.version} in '#{binary_list}.'" if binary_list.empty? || binary_list.size != 1

  value.hash = binary_list.first
rescue StandardError => _
  raise "fails in download binary: #{url} with version: #{version}"
ensure
  info_file.close
end

def download_binary_file(url, version, dst_file_path)
  output_binary = File.open(dst_file_path, 'wb+')

  puts "download binary: #{url} with version: #{version}" if PanConstants.debuging

  begin
    uri = URI(url)
    json_raw = Net::HTTP.get(uri)
    json_data = JSON.parse(json_raw)
    binary_uri = json_data[version]

    puts "binary url: #{binary_uri}"

    resp = nil
    max_limited = 10
    cur_limited = 0

    loop do
      resp = Net::HTTP.get_response(URI.parse(binary_uri))
      binary_uri = resp['location']

      cur_limited += 1
      break if cur_limited >= max_limited

      break unless resp.is_a?(Net::HTTPRedirection)
    end

    output_binary.write(resp.body)
  ensure
    output_binary.close
  end
end

def solve_project_carthage(workspace_base_dir, scheme_target, belong_to_proj_name, current_dir, is_install, is_sync)
  cartfile = {}

  # analysis the Cartfile to grab workspace's basic information
  cartfile = merge_cart_file(cartfile, read_cart_file(scheme_target.to_s, "#{current_dir}/Cartfile"))
  cartfile = merge_cart_file(cartfile, read_cart_file(scheme_target.to_s, "#{current_dir}/Cartfile.private"))

  result = CartfileBase.new(scheme_target, belong_to_proj_name)
  # setup and sync git repo
  git_repo_for_checkout = {}

  cartfile.each do |name, value|
    git_repo_for_checkout[name] = value if ProjectCartManager.instance.append_framework(value)
    # add each cartfile data into result's dependency
    result.append_dependency(value)
  end

  puts "#{scheme_target}: #{result.description}"
  puts git_repo_for_checkout.to_s

  git_repo_for_checkout.select { |_, v| v.lib_type == LibType::GIT || v.lib_type == LibType::GITHUB }.each do |name, value|
    clone_bare_repo("#{workspace_base_dir}/Carthage/Repo", name, value, is_install)
  end

  git_repo_for_checkout.select { |_, v| v.lib_type == LibType::BINARY }.each do |name, value|
    check_prepare_binary(value)
    download_binary_file(value.url, value.hash, "#{workspace_base_dir}/Carthage/.tmp/#{name}.zip")
  end

  # generate Cartfile.resolved file.
  solve_cart_file(current_dir.to_s, cartfile)

  git_repo_for_checkout.each do |name, value|
    if value.lib_type == LibType::BINARY
      # binary library had been checked and download previous step.
    elsif (value.lib_type == LibType::GIT) || (value.lib_type == LibType::GITHUB)
      RepoHelper.checkout_source("#{workspace_base_dir}/Carthage",
                                 name.to_s,
                                 value.repo_type == GitRepoType::TAG,
                                 is_sync,
                                 PanConstants.disable_verbose)
    else
      puts "???#{value.url} -> #{value.lib_type}"
    end
  end

  result
end

# solve_project_dependency
def solve_project_dependency(proj_cart_data, workspace_base_dir, is_install, is_sync)
  return if proj_cart_data.nil?
  return unless proj_cart_data.number_of_dependency.positive?

  puts ">>>>>>>>>>>>>>#{proj_cart_data.proj_name}<<<<<<<<<<<<<<<<"
  puts "Solving project: #{proj_cart_data.proj_name}, which belongs #{proj_cart_data.belong_proj_name}"

  all_proj_sub_libs = []

  proj_cart_data.dependency.each do |value|
    puts value.description.to_s

    next_proj_cart_info = solve_project_carthage(
      workspace_base_dir.to_s,
      value.proj_name.to_s,
      proj_cart_data.proj_name.to_s,
      "#{workspace_base_dir}/Carthage/Checkouts/#{value.proj_name}",
      is_install,
      is_sync
    )
    all_proj_sub_libs.push(new_proj_cart_info) if next_proj_cart_info.conflict_type == ConflictType::ACCEPT
  end

  all_proj_sub_libs.each do |value|
    puts "solving dependencies #{value.proj_name}"
    solve_project_dependency(value, workspace_base_dir, is_install, is_sync)
  end
end
