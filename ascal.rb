#!/usr/bin/env ruby

class Finfo
	attr_accessor :opts
	def initialize(opts)
		@opts = opts
		usage = "need 4 args"
		unless @opts.length == 4
			puts usage
			exit
		end
	end
	def shopt
		if @opts.respond_to?("each")
			@opts.each do |opt|
  			puts"#{opt}"
			end
		end
	end
end

if __FILE__ == $0
	fin = Finfo.new(ARGV)
	fin.shopt
end
