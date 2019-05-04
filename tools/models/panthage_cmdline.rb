# frozen_string_literal: true

require 'singleton'

# ExecuteConfig the config for runtime
class CommandLine
  include Singleton

  REG_PARAM = /^-?-(?<key>[\w-]*?)(=(?<value>.*)|)$/.freeze
  REG_FLAG = /^-?-(?<key>[\w-]*?)$/.freeze

  EXEC_INSTALL = 'install'
  EXEC_UPDATE = 'update'
  EXEC_BOOTSTRAP = 'bootstrap'

  EXEC_FLAG_SYNC = 'sync'
  EXEC_FLAG_VERBOSE = 'verbose'

  EXEC_PLATFORM = 'platform'
  EXEC_WORKSPACE = 'workspace'
  EXEC_SCHEME = 'scheme'

  attr_reader :current_dir,
              :repo_base,
              :checkout_base,
              :build_base,
              :platform,
              :scheme_target,
              :job_command,
              :using_sync,
              :verbose

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
    # initialize some vars
    @platform = XcodePlatformSDK::FOR_UNKNOWN
    @verbose = false

    argv.each do |each_arg|
      if REG_FLAG.match?(each_arg)
        match = REG_FLAG.match(each_arg)
        case match[:key]
        when EXEC_FLAG_SYNC
          @using_sync = true
        when EXEC_FLAG_VERBOSE
          @verbose = true

        when EXEC_INSTALL, EXEC_UPDATE, EXEC_BOOTSTRAP
          @job_command = match[:key]
        else
          raise "invalid parameter #{match[:key]}"
        end

      elsif REG_PARAM.match?(each_arg)
        match = REG_PARAM.match(each_arg)
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
            raise "Fatal: invalid platform #{match[:value]}"
          end
        else
          raise "invalid parameter #{match[:key]}=#{match[:value]}"
        end

      else
        puts "#{each_arg} ??"
      end
    end

    @platform = XcodePlatformSDK::FOR_IOS if @platform == XcodePlatformSDK::FOR_UNKNOWN

    # get absolute workspace path
    @current_dir = File.absolute_path(@current_dir)
    @repo_base = "#{@current_dir}/Carthage/Repo"
    @checkout_base = "#{@current_dir}/Carthage/Checkouts"
    @build_base = "#{@current_dir}/Carthage/Build"
  end
end
