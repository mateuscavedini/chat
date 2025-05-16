require 'socket'

module Chat
  class Server
    def initialize(settings)
      @host = settings[:host]
      @port = settings[:port]
      @connections = {}
      @server = Socket.new :INET, :STREAM
      @server.bind Socket.pack_sockaddr_in @port, @host
      @server.listen 5
      @mutex = Mutex.new
    end

    def start
      puts 'server running'

      loop do
        conn, _ = @server.accept
        handle_conn conn
      end
    end

    private

    def set_username(conn)
      username = nil
      loop do
        username = conn.gets(chomp: true)&.to_sym

        valid, message = validate_username username
        conn.puts message

        break if valid
      end

      @mutex.synchronize do
        @connections[username] = conn
        puts "online users: #{@connections.keys}"
      end

      username
    end

    def username_exists?(username)
      @mutex.synchronize { @connections.keys.include? username }
    end

    def validate_username(username)
      return [false, "Error: username can't be blank."] if username.nil? || username.empty?
      return [false, 'Error: username already taken.'] if username_exists? username
      return [true, "Connected as #{username}."]
    end

    def handle_conn(conn)
      Thread.new do
        username = set_username conn

        loop do
          command_str = conn.gets chomp: true
          command, receiver, msg = command_str.split ' ', 3

          if command.eql? '/s'
            sent_at = Time.now.strftime '%H:%M:%S'
            @mutex.synchronize { @connections[receiver.to_sym].puts "[#{sent_at}] #{username}> #{msg}" }
            conn.puts "[#{sent_at}] me> #{msg}"
          end
        end
      end
    end
  end
end

Chat::Server.new(host: '127.0.0.1', port: 3000).start

