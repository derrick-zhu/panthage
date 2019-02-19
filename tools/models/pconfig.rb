# frozen_string_literal: true

# ExecuteConfig the config for runtime
class ExecuteConfig
  attr_reader :current_dir
  attr_reader :repo_base
  attr_reader :checkout_base
  attr_reader :build_base
  attr_reader :scheme_target
  attr_reader :job_command
  attr_reader :using_carthage
  attr_reader :using_sync

  def initialize(argvs)
    @REG_PARAM = /^-?-(?<key>[\w-]*?)(=(?<value>.*)|)$/.freeze
    @REG_FLAG = /^-?-(?<key>[\w-]*?)$/.freeze

    parse(argvs)

    # get absolute workspace path
    @current_dir = File.absolute_path(@current_dir)
    @repo_base = "#{@current_dir}/Carthage/Repo"
    @checkout_base = "#{@current_dir}/Carthage/Checkouts"
    @build_base = "#{@current_dir}/Carthage/Build"
  end

  def parse(argv)
    argv.each do |each_arg|
      if @REG_FLAG.match?(each_arg)
        match = @REG_FLAG.match(each_arg)
        case match[:key]
        when 'using-carthage'
          @using_carthage = true
        when 'sync'
          @using_sync = true
        else
          raise "invalid parameter #{match[:key]}"
        end

      elsif @REG_PARAM.match?(each_arg)
        match = @REG_PARAM.match(each_arg)
        case match[:key]
        when 'workspace'
          @current_dir = match[:value]
        when 'target'
          @scheme_target = match[:value]
        when 'command'
          @job_command = match[:value]
        else
          raise "invalid parameter #{match[:key]}=#{match[:value]}"
        end

      else
        puts "#{each_arg} ??"
      end
    end
  end
end
