require 'deploy/namespace'

include Deploy

class Deploy::MemoryParticipationService
  def participating()
    return     @participating==true
  end

  def enable_participation()
    @participating=true
  end

  def disable_participation()
    @participating=false
  end
end