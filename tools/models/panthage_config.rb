# frozen_string_literal: true

# ExecuteConfig the config for runtime
class ExecuteConfig
  REG_PARAM = /^-?-(?<key>[\w-]*?)(=(?<value>.*)|)$/.freeze
  REG_FLAG = /^-?-(?<key>[\w-]*?)$/.freeze

  EXEC_FLAG_SYNC = 'sync'

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
              :using_sync

  def initialize(argvs)
    parse(argvs)
    # get absolute workspace path
    @current_dir = File.absolute_path(@current_dir)
    @repo_base = "#{@current_dir}/Carthage/Repo"
    @checkout_base = "#{@current_dir}/Carthage/Checkouts"
    @build_base = "#{@current_dir}/Carthage/Build"
  end

  private

  def parse(argv)
    argv.each do |each_arg|
      if REG_FLAG.match?(each_arg)
        match = REG_FLAG.match(each_arg)
        case match[:key]
        when EXEC_FLAG_SYNC
          @using_sync = true
        when Command::CMD_INSTALL, Command::CMD_UPDATE, Command::CMD_BOOTSTRAP
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
            @platform = XCodeTarget::FOR_IOS
          when 'macOS'
            @platform = XCodeTarget::FOR_MACOS
          when 'tvOS'
            @platform = XCodeTarget::FOR_TVOS
          when 'watchOS'
            @platform = XCodeTarget::FOR_WATCHOS
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

    @platform = XCodeTarget::FOR_IOS if @platform.empty? || @platform.nil?
  end
end
