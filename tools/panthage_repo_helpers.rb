#!/usr/bin/ruby
# frozen_string_literal: true

require_relative 'panthage_dependency'
require_relative 'models/panthage_cartfile_model'
require_relative 'panthage_ver_helper'

# RepoHelper
class RepoHelper
  def self.clone_bare(repo_dir, repo_url, repo_name, using_install, verbose)
    command = "cd #{repo_dir}; #{git} clone --bare -b master "
    command += '--depth 1 ' if using_install
    command += "#{repo_url} #{repo_name}.git #{verbose}; "

    system(command)
  end

  def self.reset_repo_config(repo_dir, repo_name, repo_url)
    command = [
        "cd #{repo_dir}/#{repo_name}.git; ",
        "#{git} remote remove origin; ",
        "#{git} remote add origin #{repo_url}; ",
        "#{git} config --unset-all remote.origin.fetch; ",
        "#{git} config --add remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'; ",
        "#{git} config --add remote.origin.fetch '+refs/tags/*:refs/tags/*'; "
    ].join(' ').strip.freeze

    system(command)
  end

  def self.clone_with_branch(repo_name, branch, repo_dir, _using_install, disable_verbose)
    command = [
        "cd #{repo_dir}/#{repo_name}.git; ",
        "#{git} fetch --all #{disable_verbose};",
        "#{git} symbolic-ref HEAD refs/heads/#{branch}; ",
        "#{git} branch --set-upstream-to=origin/#{branch} #{branch} >/dev/null 2>&1; "
    ].join(' ').strip.freeze
    system(command)

    commit_hash = %x(cd #{repo_dir}/#{repo_name}.git; #{git} show-ref -s #{branch} 2> /dev/null;).strip
    commit_hash = commit_hash.split("\n").first unless commit_hash.empty?

    raise "could not find #{branch} in #{repo_name}" if commit_hash.empty? || commit_hash.size != 40

    system("cd #{repo_dir}/#{repo_name}.git; #{git} update-ref refs/heads/#{branch} #{commit_hash}; ")

    commit_hash
  end

  def self.clone_with_tag(repo_name, tag, repo_dir, compare_method, disable_verbose)
    %x(cd #{repo_dir}/#{repo_name}.git; #{git} fetch --all #{disable_verbose}; #{git} reset --hard >/dev/null 2>&1;)

    tags = %x(cd #{repo_dir}/#{repo_name}.git; #{git} tag --list;)
    tags_list = []
    tags_list = tags.split("\n") unless tags.empty?
    tags_list = tags_list.each {|block| block.delete('*').strip}
    fitted_tags_list = VersionHelper.find_fit_version(tags_list, tag, compare_method)

    commit_hash = fitted_tags_list.first
    puts "#{repo_name} tags: #{tags_list}\nusing Tag: #{commit_hash}" if PanConstants.debugging
    system("cd #{repo_dir}/#{repo_name}.git; #{git} symbolic-ref HEAD refs/tags/#{commit_hash}; ")

    commit_hash
  end

  def self.checkout_source(base_dir, repo_data, using_sync, disable_verbose)
    dest_repo_dir = "#{base_dir}/Checkouts/#{repo_data.name}"
    src_binary_dir = "#{base_dir}/Build"
    src_bare_dir = "#{base_dir}/Repo/#{repo_data.name}.git"

    FileUtils.mkdir_p dest_repo_dir unless File.exist? dest_repo_dir
    FileUtils.mkdir_p src_binary_dir unless File.exist? src_binary_dir
    FileUtils.mkdir_p src_bare_dir unless File.exist? src_bare_dir

    command = "cd #{dest_repo_dir}; #{git} init --separate-git-dir=#{src_bare_dir} #{disable_verbose}; "

    if using_sync
      command += "#{git} reset --hard #{disable_verbose}; "

      if repo_data.repo_type != GitRepoType::TAG
        command += "#{git} branch --set-upstream-to=origin/#{repo_data.branch}; "
      end
    end

    # command += "mkdir -p #{dest_repo_dir}/Carthage/Checkouts/; "
    # command += "mkdir -p #{dest_repo_dir}/Carthage/; cd $_; \n"
    # command += "if [ ! -d ./Build/ ] \n" \
    #       + "then \n" \
    #       + "ln -s #{src_binary_dir} .  \n" \
    #       + "fi\n"
    #
    # repo_data.dependency.each do |lib|
    #   command += "ln -s #{base_dir}/Checkouts/#{lib.name} . ;"
    # end

    system(command)
  end

  def self.submodule_init(base_dir, repo_name)
    dest_repo_dir = "#{base_dir}/Checkouts/#{repo_name}"
    nil unless File.exist? "#{dest_repo_dir}/.gitmodules"

    system("cd #{dest_repo_dir}; #{git} submodule update --init #{PanConstants.disable_verbose} >/dev/null 2>&1;") if File.exist?(dest_repo_dir)
  end

  def self.setup_dependency(base_dir, dependency_libs)
    ;
  end

  private_class_method def self.git?
                         !%x(type git).empty?
                       end

  private_class_method def self.git
                         %x(which git).to_s.strip.freeze
                       end
end
