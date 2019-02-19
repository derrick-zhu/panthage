# frozen_string_literal: true

# IPanthageCommandProtocol about common interface
class IPanthageCommandProtocol
  def setup(_parameter)
    raise NotImplementedError, "#{self.class.name}# is an abstract class."
  end

  def run
    raise NotImplementedError, "#{self.class.name}# is an abstract class."
  end

  def finish
    raise NotImplementedError, "#{self.class.name}# is an abstract class."
  end
end

# Panthage command for install operation
class PanthageInstall < IPanthageCommandProtocol
  def initialize; end
  
end
