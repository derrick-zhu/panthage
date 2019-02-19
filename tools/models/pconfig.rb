# ExecuteConfig the config for runtime
class ExecuteConfig
  def initialize()
    @REG_PARAM = /^-?-(?<key>[\w-]*?)(=(?<value>.*)|)$/.freeze
    @REG_FLAG = /^-?-(?<key>[\w-]*?)$/.freeze

    @current_dir = ''
    @scheme_target = ''
    @job_command = ''
    @using_carthage = false
    @using_sync = false
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

    # get absolute workspace path
    @current_dir = File.absolute_path(@current_dir)
  end

end