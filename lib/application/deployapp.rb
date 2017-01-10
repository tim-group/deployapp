class AnsiStatusRenderer
  def render(statuses)
    buffer = ""
    keys = [:host, :application, :group, :present, :participating, :health]
    lengths = {}
    keys.each do |key|
      lengths[key] = key.to_s.length
    end

    statuses.each do |status|
      keys.each do |key|
        len = status[key].to_s.length
        lengths[key] = len if lengths[key] < len
      end
    end

    header_buffer = ""
    keys.each do |key|
      header_buffer << "#{key}"
      rem = lengths[key] - key.to_s.length + 1
      header_buffer << " " * rem
    end

    buffer << Color.new(:text => header_buffer).header.display

    statuses.sort_by { |s| s[:host] }.each do |status|
      color = status[:group]
      status_buffer = ""
      keys.each do |key|
        status_buffer << "#{status[key]}"
        rem = lengths[key] - status[key].to_s.length + 1
        status_buffer << " " * rem
      end
      buffer << Color.new(:text => status_buffer).color(color).display
    end

    buffer
  end

  class Color
    def initialize(args)
      @text = args[:text]
      @colors = { "cyan" => 36, "pink" => 35, "blue" => 34, "yellow" => 33, "green" => 32, "red" => 31, "grey" => 30 }
    end

    def color(color)
      @text = "\e[1;#{@colors[color]}m#{@text}\e[0m"
      self
    end

    def header
      @text = "\e[1;45m#{@text}\e[0m"
      self
    end

    def display
      "#{@text}\e[0m\n"
    end
  end
end

class MCollective::Application::Deployapp < MCollective::Application
  description "Enables manipulating deployed applications"
  usage <<-USAGE
  mco deployapp command environment application group [instance]
  USAGE

  def post_option_parser(configuration)
    command_as_hash = {
      :command     => ARGV[0],
      :environment => ARGV[1],
      :application => ARGV[2],
      :group       => ARGV[3],
      :instance    => ARGV[4].nil? ? nil : ARGV[4]
    }
    configuration.merge!(command_as_hash)
  end

  def main
    mc = rpcclient('deployapp')
    mc.progress = false

    case configuration[:command]
    when 'status'
      mc.fact_filter('logicalenv', configuration[:environment])
      mc.fact_filter('application', configuration[:application])
      mc.fact_filter('group', configuration[:group])

      statuses = []
      mc.status(configuration).each do |response|
        status = response[:data][:statuses][0]
        status[:host] = response[:sender]
        statuses << response[:data][:statuses][0]
      end

      print AnsiStatusRenderer.new.render(statuses)
    else
      fail "Unrecognised command. Run 'mco help deployapp' for usage instructions."
    end

    mc.disconnect
  end
end
