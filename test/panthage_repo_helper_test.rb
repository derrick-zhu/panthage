#!/usr/bin/ruby
# frozen_string_literal: true

require 'test/unit'
require_relative '../tools/panthage_repo_helpers'

class RepoHelperTest < Test::Unit::TestCase
  attr_accessor :base_dir
  attr_accessor :repo_name
  attr_accessor :repo_url
  attr_accessor :repo_branch
  attr_accessor :repo_tag

  def setup
    @base_dir = File.absolute_path('./../.tmp')
    @repo_name = 'LoginSlice'
    @repo_url = 'git@gitlab.fftech.info:dragon/consumer-app/LoginSlice.git'
    @repo_branch = 'develop'
    @repo_tag = '1.0.0'
  end

  def setup_env
    FileUtils.mkdir_p "#{base_dir}/Checkouts" unless File.exist? "#{base_dir}/Checkouts"
    FileUtils.mkdir_p "#{base_dir}/Build" unless File.exist? "#{base_dir}/Build"
    FileUtils.mkdir_p "#{base_dir}/Repo" unless File.exist? "#{base_dir}/Repo"
  end

  def test_clone_bare_repo
    setup_env

    RepoHelper.clone_bare("#{base_dir}/Repo/", repo_url, repo_name, false, "--quiet")

    hash = `cd #{base_dir}/Repo/#{repo_name}.git; git rev-parse HEAD`.strip.freeze
    result = File.exist? "#{base_dir}/Repo/#{repo_name}.git"
    result = result == true && hash.to_s.empty? == false

    assert(result)
  end

  def test_clone_bare_branch
    setup_env

    result_hash = RepoHelper.clone_with_branch(repo_url, repo_name, repo_branch, "#{base_dir}/Repo", false, '')
    hash = `cd #{base_dir}/Repo/#{repo_name}.git; git rev-parse HEAD`.strip.freeze

    result = File.exist? "#{base_dir}/Repo/#{repo_name}.git"
    result &&= hash == result_hash

    assert(result)
  end

  def test_clone_bare_tag
    setup_env

    result_hash = RepoHelper.clone_with_tag(repo_url, repo_name, repo_tag, "#{base_dir}/Repo/", false, "")
    hash = `cd #{base_dir}/Repo/#{repo_name}.git; git rev-parse HEAD`.strip.freeze

    result = File.exist? "#{base_dir}/Repo/#{repo_name}.git"
    result &&= hash == result_hash

    assert(result)
  end

  def test_checkout_repo
    setup_env

    RepoHelper.checkout_source(base_dir.to_s, repo_name.to_s, true, '')
    assert(true)
  end
end
