#!/usr/bin/ruby

module CommandProtocol
  attr_reader :command_line

  def initialize(cl)
    @command_line = cl
  end

  def setup
  end

  def finalize
  end

  def execute
  end
end
