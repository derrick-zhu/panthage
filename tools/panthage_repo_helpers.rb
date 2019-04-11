#!/usr/bin/ruby
# frozen_string_literal: true

require_relative 'panthage_dependency'
require_relative 'panthage_cartfile_model'
require_relative 'panthage_ver_helper'

# RepoHelper
class RepoHelper
  def self.clone_bare(repo_dir, repo_url, repo_name, using_install, verbose)
    command = "cd #{repo_dir}; git clone --bare -b master "
    command += '--depth 1 ' if using_install
    command += "#{repo_url} #{repo_name}.git #{verbose}; "
    command += "cd #{repo_name}.git; git remote remove origin; git remote add origin #{repo_url}; "
    command += "git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'; "

    system(command)
  end

  def self.clone_with_branch(repo_url, repo_name, branch, repo_dir, _using_install, disable_verbose)
    `cd #{repo_dir}/#{repo_name}.git; git fetch --all #{disable_verbose}; `

    branches = `cd #{repo_dir}/#{repo_name}.git; git branch --list;`
    branches_list = branches.split("\n") if branches.empty? == false
    finded = branches_list.select { |block| block.delete('*').strip == branch }.empty? == false

    raise "could not find '#{branch}' in '#{repo_url}'. " unless finded

    command = "cd #{repo_dir}/#{repo_name}.git; "
    command += "git branch #{branch} 2> /dev/null; "
    command += "git symbolic-ref HEAD refs/heads/#{branch}; "
    command += "git branch --set-upstream-to=origin/#{branch} #{branch}; "
    system(command)

    commit_hash = `cd #{repo_dir}/#{repo_name}.git; git rev-parse HEAD 2> /dev/null;`.strip.freeze
    system("cd #{repo_dir}/#{repo_name}.git; git update-ref refs/heads/#{branch} #{commit_hash}; ")

    commit_hash
  end

  def self.clone_with_tag(repo_url, repo_name, tag, repo_dir, compare_method, disable_verbose)
    `cd #{repo_dir}/#{repo_name}.git; git fetch --all #{disable_verbose}; `

    tags = `cd #{repo_dir}/#{repo_name}.git; git tag --list;`
    tags_list = tags.split("\n") if tags.empty? == false
    tags_list = tags_list.each { |block| block.delete('*').strip }
    fitted_tags_list = VersionHelper.find_fit_version(tags_list, tag, compare_method)

    raise "could not find `#{tag}` in '#{repo_url}'." if fitted_tags_list.empty?

    commit_hash = fitted_tags_list.first
    puts "#{repo_name} tags: #{tags_list}\nusing Tag: #{commit_hash}" if PanConstants.debuging
    system("cd #{repo_dir}/#{repo_name}.git; git symbolic-ref HEAD refs/tags/#{commit_hash}; ")

    commit_hash
  end

  def self.checkout_source(base_dir, repo_name, is_tag, using_sync, disable_verbose)
    dest_repo_dir = "#{base_dir}/Checkouts/#{repo_name}"
    src_binary_dir = "#{base_dir}/Build"
    src_bare_dir = "#{base_dir}/Repo/#{repo_name}.git"

    FileUtils.mkdir_p dest_repo_dir unless File.exist? dest_repo_dir
    FileUtils.mkdir_p src_binary_dir unless File.exist? src_binary_dir
    FileUtils.mkdir_p src_bare_dir unless File.exist? src_bare_dir

    command = "cd #{dest_repo_dir}; git init --separate-git-dir=#{src_bare_dir} #{disable_verbose}; "
    command += if using_sync
                 "git reset --hard #{disable_verbose}; "
               else
                 "git reset #{disable_verbose}; "
               end
    command += 'git pull; ' if using_sync && !is_tag
    command += "mkdir -p #{dest_repo_dir}/Carthage/Checkouts/; "
    command += "mkdir -p #{dest_repo_dir}/Carthage/; cd $_; \n"
    command += "if [ ! -d ./Build/ ] \n" \
    + "then \n" \
    + "ln -s #{src_binary_dir} .  \n" \
    + "fi\n"

    system(command)
  end
end
