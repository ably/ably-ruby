require 'eventmachine'
require 'em/resolver'
require 'em-http-request'
require 'em-resolv-replace'

puts "Using #{EventMachine::DNS::Resolver::Port}"

class Request < EventMachine::Connection
  def post_init
    puts "Sending GET request"
    send_data "GET /\n\n"
  end

  def receive_data(data)
    puts "Reponse:\n#{data}"
    EventMachine.stop
  end
end

def connect_and_stop(host, port)
  puts "#{Time.now}: Starting socket test for #{host}:#{port}"
  EventMachine.run do
    EventMachine::PeriodicTimer.new(0.2) { puts "#{Time.now}: ...tick socket... #{host}:#{port}" }
    EventMachine::Timer.new(5) { puts "#{Time.now}: Socket timed out for #{host}:#{port}"; EventMachine.stop }
    EventMachine::connect host, port, Request
  end
end

def http_request(host, port)
  puts "#{Time.now}: Starting EM-HTTP test for #{host}:#{port}"
  EventMachine.run do
    EventMachine::PeriodicTimer.new(0.2) { puts "#{Time.now}: ...tick http... #{host}:#{port}" }
    EventMachine::Timer.new(5) { puts "#{Time.now}: HTTP timed out for #{host}:#{port}"; EventMachine.stop }
    http = EventMachine::HttpRequest.new("http://#{host}:#{port}/").get
    http.errback do
      puts "#{Time.now}: Error - HTTP request failed #{host}:#{port}"
      EventMachine.stop
    end
    http.callback do |result|
      puts "#{Time.now}: HTTP request successful http://#{host}:#{port}/"
      EventMachine.stop
    end
  end
end

def resolve_dns(host)
  puts "#{Time.now}: Resolving DNS for #{host}"
  EventMachine.run do
    EventMachine::PeriodicTimer.new(0.2) { puts "#{Time.now}: ...tick DNS resolving for #{host}..." }
    EventMachine::Timer.new(5) { puts "#{Time.now}: Timed out resolving host #{host}"; EventMachine.stop }
    dns = EventMachine::DNS::Resolver.resolve host
    dns.errback do
      puts "#{Time.now}: Error - could not resolve DNS #{host}"
      EventMachine.stop
    end
    dns.callback do |result|
      puts "#{Time.now}: Resolved #{host} to #{result}"
      EventMachine.stop
    end
  end
end

# valid_host = "www.google.com"
# resolve_dns valid_host
# connect_and_stop valid_host, 80
# connect_and_stop valid_host, 14441
# http_request valid_host, 80

invalid_host = "this.host.does.not.exist"
require 'pry'; binding.pry
# resolve_dns invalid_host

# http_request invalid_host, 80
connect_and_stop invalid_host, 80
