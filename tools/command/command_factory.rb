#!/usr/bin/ruby

require_relative '../models/panthage_cmdline'
require_relative 'command_install'
require_relative 'command_update'
require_relative 'command_bootstrap'

class CommandFactory
  def self.get_command(p_cl)
    case p_cl.command
    when CommandLine::EXEC_INSTALL
      CommandInstall.new(p_cl)
    when CommandLine::EXEC_UPDATE
      CommandUpdate.new(p_cl)
    when CommandLine::EXEC_BOOTSTRAP
      CommandBootstrap.new(p_cl)
    else
      raise "fatal: unknown command: #{p_cl.command}"
    end
  end
end
