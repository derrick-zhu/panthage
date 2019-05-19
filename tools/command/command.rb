#!/usr/bin/ruby

module CommandProtocol
  attr_reader :command_line

  attr_accessor :scheme_target,
                :command,
                :using_sync,
                :current_dir,
                :repo_base,
                :checkout_base,
                :build_base

  def initialize(cl)
    @command_line = cl
  end

  def setup
    self.scheme_target = self.command_line.scheme_target
    self.command = self.command_line.command
    self.using_sync = self.command_line.using_sync

    # get absolute workspace path
    self.current_dir = self.command_line.current_dir
    self.repo_base = self.command_line.repo_base
    self.checkout_base = self.command_line.checkout_base
    self.build_base = self.command_line.build_base
  end

  def finalize
  end

  def execute
  end
end
