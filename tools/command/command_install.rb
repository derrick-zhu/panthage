#!/usr/bin/ruby

require_relative 'command'

require 'fileutils'
require 'xcodeproj'
require 'net/http'
require 'json'

require_relative '../extensions/fileutils_ext'
require_relative '../extensions/string_ext'
require_relative '../models/panthage_cmdline'
require_relative '../panthage_dependency'
require_relative '../panthage_utils'
require_relative '../xcode_proj/models/panthage_xc_scheme_model'
require_relative '../xcode_proj/panthage_xcode_builder_config'
require_relative '../xcode_proj/panthage_xcode_builder'
require_relative '../panthage_cache_version'

require_relative 'helpers/command_helpers'
require_relative 'install/command_install+utils'

class CommandInstall
  include CommandProtocol
  include CommandHelper

  def setup
    super
  end

  def finalize
    super
  end

  def execute
    super

    setup_carthage_env(current_dir.to_s)

    CommandHelper.solve_dependency(current_dir, scheme_target, 'main', self.command_line)

    puts ProjectCartManager.instance.description.reverse_color.to_s if PanConstants.debugging
    puts ProjectCartManager.instance.resolved_info if PanConstants.debugging

    CommandHelper.write_solved_info("#{self.command_line.current_dir}/Cartfile.resolved")
    CommandHelper.link_carthage_fold(self)

    # build the source dependency framework
    CommandHelper.build_all(self)

    # setup the xcode project with sub project's relation tree
    CommandHelper.setup_xcodeproj(self)

    puts '-------------------------------------------------'
    puts 'DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!DONE!!!'

  end
end
