module Helpers
	def validate_args(args)
		begin
			DateTime.parse args[0]
			DateTime.parse args[1]
		rescue ArgumentError => e
		  raise "arguments must be dates in format 2015-01-01-12 #{e}"
		end

		raise "wrong number of arguments, please send in start and end dates" if args.length != 2

		return args[0], args[1]
	end
end