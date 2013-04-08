require 'em-http-request'

class PublicIpChecker

  Urls = %w( http://checkip.amazonaws.com/ http://checkip.dyndns.org/ http://ifconfig.me/ip http://corz.org/ip )

  def initialize limit=2
    @limit         = limit
    @urls          = Urls
    @retrieved_ips = []
  end

  def check
    run_check_machine
  end

private

  def run_check_machine
    EventMachine.run {
      multi = EventMachine::MultiRequest.new

      @urls.each_with_index do |url, idx|
        http = EventMachine::HttpRequest.new(url, :connect_timeout => 1)
        req = http.get
        multi.add idx, req

        req.callback do
          @retrieved_ips << match_response(req.response)
          EventMachine.stop if @retrieved_ips.compact.size == @limit
        end
      end

      multi.callback  do
        EventMachine.stop
      end
    }

    puts "Your public ip : #{@retrieved_ips.first}"
  end

  # retrieve ip address from response, removing html tag etc.
  def match_response response
    response.match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/) ? response : response[/.*: ([^<]+)<.*/, 1] 
  rescue
    nil
  end
end

if __FILE__ == $0
  p = PublicIpChecker.new
  p.check
end