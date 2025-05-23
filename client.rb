require 'socket'

module Chat
  class Client
    def initialize(settings)
      @host = settings[:host]
      @port = settings[:port]
      @client = Socket.new :INET, :STREAM
    end

    def start
      @client.connect Socket.pack_sockaddr_in @port, @host

      loop do
        username = set_username

        server_response = @client.gets chomp: true
        puts server_response

        break if server_response.eql? "Connected as #{username}."
      end

      Thread.new do
        loop { puts @client.gets }
      end

      loop do
        command_str = gets.chomp
        print "\e[A\e[K"
        @client.puts command_str
      end
    end

    private

    def set_username
      username = nil
      loop do
        print 'Insert your username: '
        username = gets.chomp
        break unless username.nil? || username.empty?

        puts "Error: username can't be blank."
      end

      @client.puts username

      username
    end
  end
end

Chat::Client.new(host: '127.0.0.1', port: 3000).start

