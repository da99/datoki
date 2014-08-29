
require 'mechanize'

IP = '127.0.0.1'

module Server
  module Test

    def client
      @client ||= begin
                    puts "New client"
                    agent = Mechanize.new
                    # http://icfun.blogspot.com/2012/05/ruby-opensslsslsslerror-with-mechanize.html
                    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                    @_get = agent.get('https://localhost/')
                    agent
                  end
    end

    def _csrf
      @_csrf ||= (@_get / '#CSRF').first.content
    end

    def GET url, *args
      client.get "https://localhost#{url}", *args
    end

    def POST url, data, headers = {}
      data = MultiJson.dump(data)
      headers['Cookie'] = @_get.header['set-cookie']
      headers['Content-Type'] = 'application/json'
      headers['X-CSRF-Token'] = _csrf if !headers.has_key?('X-CSRF-Token')
      client.post "https://localhost#{url}", data, headers
    end

    def tests_started? *args
      if args.empty?
        @started
      else
        @started = args.first
      end
    end


    def start_server
      # `pkill -HUP -f "unicorn master"`
      # require 'pty'

      # f = nil

      # kill = lambda { |*a|
        # old = `ps aux`['unicorn master']
        # `pkill -QUIT -f "unicorn master"`
        # f.resume if f && tests_started?
        # puts "=== Server killed\n\n" if old
      # }

      # Signal.trap("INT", lambda { 
        # kill.call
        # exit
      # })
      # Signal.trap("EXIT", lambda { 
        # kill.call
        # exit
      # })

      # kill.call


      # catch :ready do
      # # f = Fiber.new {
        # PTY.spawn( "bin/start" ) do |stdin, stdout, pid|
        # begin
          # # Do stuff with the output here. Just printing to show it works
          # stdin.each { |line|
            # print line #if line['app error']
            # # Fiber.yield if tests_started? || (line['worker'] && line['read'])
            # throw :ready if (line['worker'] && line['read'])
          # }
        # rescue Errno::EIO
          # exit 1 if !tests_started?
          # # puts "=== Server output has ended.\n\n"
          # Fiber.yield
        # end
        # end
      # # }
      # end

      # # f.resume

      # tests_started? true

    end # === def start_server


  end # === module Test ===
end # === module Server ===

