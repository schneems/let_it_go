
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
      #   [
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
        @raw.find {|x| x.first == :call || x.first == :fcall}
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
        args_paren.last || @raw.find {|x| x.first == :args_add_block } || []
      end

      def args
        args = (args_add_block.first(2).last || [])
        case args.first
        when :args_add_star
          args.shift
          args
        else
          args
        end
      end

    # [:fcall, [:@ident, "foo", [1, 6]]],
    #    [:arg_paren,
    #     [:args_add_block, [:args_add_star, [], [:array, nil]], false]]

    # [:args_add_star, [], [:array, nil]], false]

      # Returns argument types as an array of symbols [:regexp_literal, :string_literal]
      def arg_types
        args.map(&:first).map {|x| x.is_a?(Array) ? x.first : x }.compact
      end
    end

    # I think "command calls" are method invocations without parens
    # Like `puts "hello world"`. For some unholy reason, their structure
    # is different than regular method calls?
    class CommandCall < MethodAdd
      # @raw =
      # [
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
        @raw.find {|x| x.is_a?(Array) ? x.first == :args_add_block : false } || []
      end

      def args
        args_add_block.first(2).last || []
      end

      # Returns argument types as an array of symbols [:regexp_literal, :string_literal]
      def arg_types
        args.map(&:first).map {|x| x.is_a?(Array) ? x.first : x }.compact
      end
    end

    # These are calls to operators that take 1 argument such as `1 + 1` or `[] << 1`
    class BinaryCall
      # @raw =
      # [
      #   [:string_literal, [:string_content, [:@tstring_content, "hello", [1, 7]]]],
      #   :+,
      #   [:string_literal,
      #    [:string_content, [:@tstring_content, "there", [1, 17]]]]]
      def initialize(ripped_code)
        ripped_code = ripped_code.dup
        raise "Wrong node" unless ripped_code.shift == :binary
        @raw = ripped_code
      end

      # For `1 + 1` we want to pull "+"
      def method_name
        @raw[1].to_s
      end

      def args
        [@raw.last]
      end

      def arg_types
        args.map(&:first).map {|x| x.is_a?(Array) ? x.first : x }.compact
      end
    end

    attr_accessor :contents

    def initialize(ripped_code, contents: "")
      @contents   = contents
      @raw = ripped_code || []
    end

    # Parses raw input recursively looking for :method_add_arg blocks
    def find_method_add_from_raw(ripped_code, array = [])
      return false unless ripped_code.is_a?(Array)

      case ripped_code.first
      when :method_add_arg
        array << MethodAdd.new(ripped_code)
        ripped_code.shift
      when :command_call
        array << CommandCall.new(ripped_code)
        ripped_code.shift
      when :binary
        array << BinaryCall.new(ripped_code)
        ripped_code.shift
      end
      ripped_code.each do |code|
        find_method_add_from_raw(code, array) unless ripped_code.empty?
      end
    end

    def all_methods
      @method_add_array ||= begin
        method_add_array = []
        find_method_add_from_raw(@raw.dup, method_add_array)
        method_add_array
      end
    end
    alias :method_add :all_methods

    def each
      begin
        if block_given?
          all_methods.each do |obj|
            begin
              yield obj
            rescue => e
            end
          end
        else
          enum_for(:each)
        end
      rescue => e
        msg = "Could not parse seemingly valid Ruby code:\n\n"
        msg << "    #{ parser.contents.inspect }\n\n"
        msg << e.message
        raise e, msg
      end
    end
    alias :each_method :each

    include Enumerable
  end
end