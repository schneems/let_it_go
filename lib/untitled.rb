require 'ripper'
require 'pp'

# code = <<-CODE
#   "foo".gsub(//, "blerg".downcase)
# CODE

# ripped_code = Ripper.sexp(code)

code = <<-CODE
  "foo".gsub //, "blerg".downcase
CODE

ripped_code = Ripper.sexp(code)
# pp ripped_code

puts "============="


# code = <<-CODE
#   ["hello"] << "there"
# CODE

# ripped_code = Ripper.sexp(code)
# pp ripped_code


code = <<-CODE
  ps.find_all { |l| followpos(l).include?(DUMMY) }
CODE
ripped_code = Ripper.sexp(code)
pp ripped_code

def find_method_adds(ripped_code, array = [])
  return false unless ripped_code.is_a?(Array)
  case ripped_code.first
  when :method_add_arg, :command_call, :binary
    array << ripped_code
    ripped_code.shift
    ripped_code.each do |code|
      find_method_adds(code, array)
    end
  else
    ripped_code.each do |code|
      find_method_adds(code, array) unless ripped_code.empty?
    end
  end
end

array = []
find_method_adds(ripped_code, array)

array.uniq!

puts array.count
pp array



def foo
end

# trace = TracePoint.trace(:call, :c_call) do |tp|
#   tp.disable
#   puts "=="
#   puts tp.defined_class
#   puts tp.method_id.inspect
#   tp.enable
# end

# trace.enable

# a = rand
# "blahblah" << "blah #{a}"

foo()


