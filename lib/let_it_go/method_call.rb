require 'let_it_go/wtf_parser'

module LetItGo
  # Wraps logic that require knowledge of the method call
  # can parse original method call's source and determine if a string literal
  # was passed into the method.
  class MethodCall
    attr_accessor :klass, :method_name, :positions, :line_number, :file_name, :call_count

    def initialize(klass: , method_name: , kaller:, positions: )
      @klass        = klass
      @method_name  = method_name.to_s
      # Subclasses report method definition as caller.first via TracePoint
      @key          = "Method: #{klass}##{method_name} [#{kaller.first(2).inspect}]"
      @caller_lines = kaller.first(2).map {|kaller_line| CallerLine.new(kaller_line) }
      @positions    = positions
      @call_count   = 0
    end

    def count
      call_count * string_allocation_count
    end

    def zero?
      count.zero?
    end

    # Loop through each line in the caller and see if the method we're watching is being called
    # This is needed due to the way TracePoint deals with inheritance
    def method_array
      @parser = nil
      @caller_lines.each do |kaller|
        code   = Ripper.sexp(kaller.contents)
        code  ||= Ripper.sexp(kaller.contents.sub(/^\W*(if|unless)/, ''.freeze)) # if and unless "block" statements aren't valid one line ruby code
        code  ||= Ripper.sexp(kaller.contents.sub(/do \|.*\|$/, ''.freeze)) # remove trailing do |thing| to make valid code
        code  ||= Ripper.sexp(kaller.contents.sub(/(and|or)\W*$/, ''.freeze))# trailing and || or
        code  ||= Ripper.sexp(kaller.contents.sub(/:\W*$/, ''.freeze)) # multi line ternary statements
        code  ||= Ripper.sexp(kaller.contents.sub(/(^\W*)|({ \|?.*\|?)}/, ''.freeze)) # multi line blocks using {}

        puts "LetItGoFailed parse (#{kaller.file_name}:#{kaller.line_number}: \n  \033[0;31m"+ kaller.contents.strip + "\e[0m".freeze if ENV['LET_IT_GO_RECORD_FAILED_CODE'] && code.nil? && kaller.contents.match(/"|'/)

        parser = ::LetItGo::WTFParser.new(code, contents: kaller.contents)

        if parser.each_method.any? { |m| m.method_name == method_name }
          @line_number = kaller.line_number
          @file_name   = kaller.file_name

          @parser = parser
          parser.each_method.each(&:arg_types)
          break
        else
          next
        end
      end
      @parser || []
    end

    def line_to_s
      @line_to_s ||= contents_from_file_line(file_name, line_number)
    end

    def optimizable?
      @optimizable ||= called_with_string_literal?
    end

    def string_allocation_count
      @string_allocation_count
    end

    # Parses original method call location
    # Determines if a string literal was used or not
    def called_with_string_literal?
      @string_allocation_count = 0
      method_array.each do |m|
        positions.each {|position| @string_allocation_count += 1 if m.arg_types[position] == :string_literal }
        @string_allocation_count += 1 if m.receiver == :string_literal
      end
      !@string_allocation_count.zero?
    end

    # Needs to be very low cost, cannot incur disk read
    def key
      @key
    end
  end
end