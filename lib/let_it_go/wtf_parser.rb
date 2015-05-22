
module LetItGo
  # Used for parsing the output of Ripper from a single line of Ruby.
  #
  # Pulls out method calls, and arguments to those method calls.
  # We only care about when a string literal isn't frozen
  class WTFParser

    # Holds the "MethodAdd" components of parsed Ripper output
    # Capable of pulling out `method_name`, and argument types such as
    # :string_literal
    class MethodAdd
      # @raw =
      #   [:call,
      #    [:string_literal, [:string_content, [:@tstring_content, "foo", [1, 7]]]],
      #    :".",
      #    [:@ident, "gsub", [1, 12]]],
      #   [:arg_paren,
      #    [:args_add_block,
      #     [[:regexp_literal, [], [:@regexp_end, "/", [1, 18]]],
      #      [:string_literal,
      #       [:string_content, [:@tstring_content, "blerg", [1, 22]]]]],
      #     false]]
      def initialize(ripped_code)
        ripped_code = ripped_code.dup
        raise "Wrong node" unless ripped_code.shift == :method_add_arg
        @raw = ripped_code
      end

      # [
      #  :call,
      #  [:string_literal, [:string_content, [:@tstring_content, "foo", [1, 7]]]],
      #  :".",
      #  [:@ident, "gsub", [1, 12]]
      # ]
      def call
        @raw.find {|x| x.first == :call}
      end

      # For gsub we want to pull from [:@ident, "gsub", [1, 12]] from `call`
      def method_name
        call.find {|x| x.is_a?(Array) && x.first == :@ident }[1]
      end

      # [:arg_paren,
      #   [
      #     :args_add_block,
      #     # ..
      #   ]
      def args_paren
        @raw.find {|x| x.first == :arg_paren } || []
      end

      # [:args_add_block,
      #  [[:regexp_literal, [], [:@regexp_end, "/", [1, 18]]],
      #   [:string_literal, [:string_content, [:@tstring_content, "blerg", [1, 22]]]]],
      #  false]
      #
      # or
      #
      # [:args_add_block,
       #    [[:regexp_literal, [], [:@regexp_end, "/", [1, 18]]],
       #     [[:call,
       #       [:string_literal,
       #        [:string_content, [:@tstring_content, "bar", [1, 22]]]],
       #       :".",
       #       [:@ident, "gsub!", [1, 27]]],
       #      [:arg_paren,
       #       [:args_add_block,
       #        [[:regexp_literal, [], [:@regexp_end, "/", [1, 34]]],
       #         [:string_literal,
       #          [:string_content, [:@tstring_content, "zoo", [1, 38]]]]],
       #        false]]]],
       #    false]]]
      def args_add_block
        args_paren.last || @raw.find {|x| x.first == :args_add_block }
      end

      def args
        args_add_block.first(2).last || []
      end

      # Returns argument types as an array of symbols [:regexp_literal, :string_literal]
      def arg_types
        args.map(&:first).map {|x| x.is_a?(Array) ? x.first : x }
      end
    end

    # I think "command calls" are method invocations without parens
    # Like `puts "hello world"`. For some unholy reason, their structure
    # is different than regular method calls?
    class CommandCall < MethodAdd
      # @raw =
      # [:command_call,
      #  [:string_literal, [:string_content, [:@tstring_content, "foo", [1, 7]]]],
      #  :".",
      #  [:@ident, "gsub", [1, 12]],
      #  [:args_add_block,
      #   [[:regexp_literal, [], [:@regexp_end, "/", [1, 18]]],
      #    [:call,
      #     [:string_literal,
      #      [:string_content, [:@tstring_content, "blerg", [1, 22]]]],
      #     :".",
      #     [:@ident, "downcase", [1, 29]]]],
      #   false]]
      def initialize(ripped_code)
        ripped_code = ripped_code.dup
        raise "Wrong node" unless ripped_code.shift == :command_call
        @raw = ripped_code
      end

      def method_name
        @raw.find {|x| x.is_a?(Array) ? x.first == :@ident : false }[1]
      end

      def args_add_block
        @raw.find {|x| x.is_a?(Array) ? x.first == :args_add_block : false }
      end

      def args
        args_add_block.first(2).last || []
      end

      # Returns argument types as an array of symbols [:regexp_literal, :string_literal]
      def arg_types
        args.map(&:first).map {|x| x.is_a?(Array) ? x.first : x }
      end

    end

    def initialize(ripped_code)
      @raw = ripped_code
    end

    # Parses raw input recursively looking for :method_add_arg blocks
    def find_method_add_from_raw(ripped_code, array = [])
      return false unless ripped_code.is_a?(Array)
       if ripped_code.first == :method_add_arg || ripped_code.first == :command_call
        array << MethodAdd.new(ripped_code)   if ripped_code.first  == :method_add_arg
        array << CommandCall.new(ripped_code) if ripped_code.first  == :command_call
        ripped_code.shift
        ripped_code.each do |code|
          find_method_add_from_raw(code, array)
        end
      else
        ripped_code.each do |code|
          find_method_add_from_raw(code, array) unless ripped_code.empty?
        end
      end
    end

    def method_add
      @method_add_array ||= begin
        method_add_array = []
        find_method_add_from_raw(@raw.dup, method_add_array)
        method_add_array
      end
    end

    def each_method
      if block_given?
        method_add.each do |obj|
          yield obj
        end
      else
        enum_for(:each_method)
      end
    end
  end
end