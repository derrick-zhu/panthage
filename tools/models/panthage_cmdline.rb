# frozen_string_literal: true

require 'singleton'

# ExecuteConfig the config for runtime
class CommandLine
  include Singleton

  REG_PARAM = /^-?-(?<key>[\w-]*?)(=(?<value>.*)|)$/.freeze
  REG_FLAG = /^-?-(?<key>[\w-]*?)$/.freeze
  REG_CMD = /^(?<key>[\w\-_]*?)$/.freeze

  OUTPUT_ALL = ''
  OUTPUT_ERROR = '1>/dev/null'
  OUTPUT_INFO = '2>/dev/null'
  OUTPUT_MUTE = '>/dev/null 2>&1'

  EXEC_DOCTOR = 'doctor'  # analytic the run-time env, checking ruby 3rd party list.
  EXEC_BRIEF = 'brief'  # check and show current project's has the dependent loop or not
  EXEC_INSTALL = 'install'
  EXEC_UPDATE = 'update'
  EXEC_BOOTSTRAP = 'bootstrap'

=begin
  FLAGS for config the panthage's behavior details.
=end
  EXEC_FLAG_NO_SYNC = 'no-sync'

  EXEC_FLAG_MUTE = 'mute'
  EXEC_FLAG_VERBOSE = 'verbose'
  EXEC_FLAG_ERROR = 'show-error' # default output level
  EXEC_FLAG_INFO = 'show-info'

  EXEC_PLATFORM = 'platform'
  EXEC_WORKSPACE = 'workspace'
  EXEC_SCHEME = 'scheme'

  attr_reader :current_dir,
              :repo_base,
              :checkout_base,
              :build_base,
              :platform,
              :scheme_target,
              :command,
              :using_sync,
              :verbose,
              :verbose_level,
              :need_show_help

  def initialize
    @platform = XcodePlatformSDK::FOR_UNKNOWN
    @verbose = false
    @using_sync = true    # sync from the remote repo by default value
    @verbose_level = EXEC_FLAG_MUTE
    @need_show_help = false

    @verbose_levels = {
        EXEC_FLAG_MUTE: OUTPUT_MUTE,
        EXEC_FLAG_VERBOSE: OUTPUT_ALL,
        EXEC_FLAG_ERROR: OUTPUT_ERROR,
        EXEC_FLAG_INFO: OUTPUT_INFO
    }
  end

  def verbose_flag
    @verbose ? @verbose_levels[@verbose_level] : OUTPUT_MUTE
  end

  def self.install?(cmd)
    cmd == EXEC_INSTALL
  end

  def self.update?(cmd)
    cmd == EXEC_UPDATE
  end

  def self.bootstrap?(cmd)
    cmd == EXEC_BOOTSTRAP
  end

  def parse(argv)
    argv.each do |each_arg|
      if REG_FLAG.match?(each_arg)
        match_flag(each_arg)
      elsif REG_PARAM.match?(each_arg)
        match_arguments(each_arg)
      elsif REG_CMD.match?(each_arg)
        match_command(each_arg)
      else
        puts "#{each_arg} ??"
        @need_show_help = true
      end
    end

    @platform = XcodePlatformSDK::FOR_IOS if @platform == XcodePlatformSDK::FOR_UNKNOWN

    # get absolute workspace path
    @current_dir = File.absolute_path(@current_dir)
    @repo_base = "#{@current_dir}/Carthage/Repo"
    @checkout_base = "#{@current_dir}/Carthage/Checkouts"
    @build_base = "#{@current_dir}/Carthage/Build"

    self
  end

  private

  def match_command(argument)
  meta = REG_CMD.match(argument)
  case meta[:key]
  when EXEC_INSTALL, EXEC_UPDATE, EXEC_BOOTSTRAP
      @command = meta[:key]
  else
    @need_show_help = true
  end
  end

  def match_flag(argument)
    match = REG_FLAG.match(argument)
    case match[:key]
    when EXEC_FLAG_NO_SYNC
      @using_sync = false

    when EXEC_FLAG_VERBOSE, EXEC_FLAG_ERROR, EXEC_FLAG_INFO
      @verbose = true
      @verbose_level = match[:key]

    # when EXEC_INSTALL, EXEC_UPDATE, EXEC_BOOTSTRAP
    #   @command = match[:key]
    else
      puts "invalid parameter #{match[:key]}"
      @need_show_help = true
    end
  end

  def match_arguments(argument)
    match = REG_PARAM.match(argument)
    case match[:key]
    when EXEC_WORKSPACE
      @current_dir = match[:value]
    when EXEC_SCHEME
      @scheme_target = match[:value]
    when EXEC_PLATFORM
      case match[:value]
      when 'iOS'
        @platform = XcodePlatformSDK::FOR_IOS
      when 'macOS'
        @platform = XcodePlatformSDK::FOR_MACOS
      when 'tvOS'
        @platform = XcodePlatformSDK::FOR_TVOS
      when 'watchOS'
        @platform = XcodePlatformSDK::FOR_WATCHOS
      else
        puts "Fatal: invalid platform #{match[:value]}"
        @need_show_help = true
      end
    else
      puts "invalid parameter #{match[:key]}=#{match[:value]}"
      @need_show_help = true
    end
  end
end
