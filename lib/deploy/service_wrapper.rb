require 'deploy/namespace'

class Deploy::ServiceWrapper
  def start_service(service_name)
    system("service #{service_name} start")
  end

  def stop_service(service_name)
    system("service #{service_name} stop")
  end
end

