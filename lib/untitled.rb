require 'ripper'
require 'pp'


[:program,
 [[:command_call,
   [:string_literal, [:string_content, [:@tstring_content, "foo", [1, 3]]]],
   :".",
   [:@ident, "gsub", [1, 8]],
   [:args_add_block,
    [[:regexp_literal, [], [:@regexp_end, "/", [1, 14]]],
     [:call,
      [:string_literal,
       [:string_content, [:@tstring_content, "blerg", [1, 18]]]],
      :".",
      [:@ident, "downcase", [1, 25]]]],
    false]]]]


[:program,
 [[:method_add_arg,
   [:call,
    [:string_literal, [:string_content, [:@tstring_content, "foo", [1, 3]]]],
    :".",
    [:@ident, "gsub", [1, 8]]],
   [:arg_paren,
    [:args_add_block,
     [[:regexp_literal, [], [:@regexp_end, "/", [1, 14]]],
      [:call,
       [:string_literal,
        [:string_content, [:@tstring_content, "blerg", [1, 18]]]],
       :".",
       [:@ident, "downcase", [1, 25]]]],
     false]]]]]


code = <<-CODE
  "foo".gsub(//, "blerg".downcase)
CODE

ripped_code = Ripper.sexp(code)

code = <<-CODE
  "foo".gsub //, "blerg".downcase
CODE

ripped_code = Ripper.sexp(code)

pp ripped_code

def find_method_adds(ripped_code, array = [])
  return false unless ripped_code.is_a?(Array)
  if ripped_code.first == :method_add_arg || ripped_code.first == :command_call
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


def call(array)
  array.map {|x| }
end