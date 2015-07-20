require 'ripper'
require 'pp'
require 'thread'

require "let_it_go/version"

module LetItGo
end

require 'let_it_go/wtf_parser'

module LetItGo
  @mutex    = Mutex.new
  @watching = {}

  def self.watching_klasses
    @watching.keys
  end

  def self.method_hash_for_klass(klass)
    @watching[klass]
  end


  def self.watching_positions(klass, method)
    @watching[klass] && @watching[klass][method]
  end

  # Main method, wrap code you want to check for frozen violations in
  # a `let_it_go` block.
  #
  # By default it will try to parse source of the method call to determine
  # if a string literal or variable was used. We only care about string literals.
  def self.record
    @mutex.synchronize do
      Thread.current[:let_it_go_recording]    = :on
      Thread.current[:let_it_go_records]      = {} # nil => never checked, 0 => checked, no string literals, positive => checked, positive literals detected
    end
    yield
    records = Thread.current[:let_it_go_records]
    report  = Report.new(records)
    return report
  ensure
    @mutex.synchronize do
      Thread.current[:let_it_go_recording]    = nil
      Thread.current[:let_it_go_records]      = nil
    end
  end

  class << self
    alias :cant_hold_it_back_anymore         :record
    alias :do_you_want_to_build_a_snowman    :record
    alias :turn_away_and_slam_the_door       :record
    alias :the_cold_never_bothered_me_anyway :record
    alias :let_it_go                         :record
  end

  def self.recording?
    Thread.current[:let_it_go_recording] == :on
  end

  # Takes a caller array and converts each to the contents of the line in the given file
  class CallerParser
    include Enumerable

    def initialize(kaller)
      @kaller = kaller
    end

    def each
      if block_given?
        @kaller.each do |string|
          yield contents(string)
        end
      else
        enum_for(:each)
      end
    end

    def contents(string)
      file_line       = string.split(":in `".freeze).first
      file_line_array = file_line.split(":".freeze)

      line_number = file_line_array.pop
      file_name   = file_line_array.join(":".freeze) # name may have `:` in it
      read(file_name, line_number)
    end

    private
      def read(file_name, line_number)
        contents = ""
        File.open(file_name).each_with_index do |line, index|
          next unless index == Integer(line_number).pred
          contents = line
          break
        end
        contents
      rescue Errno::ENOENT
        nil
      end
  end

  # Wraps logic that require knowledge of the method call
  # can parse original method call's source and determine if a string literal
  # was passed into the method.
  class MethodCall
    attr_accessor :klass, :method_name, :kaller, :positions

    def initialize(klass: , method_name: , kaller:, positions: )
      @klass        = klass
      @method_name  = method_name
      @kaller       = kaller
      @positions    = positions
      @kaller       = CallerParser.new(kaller)
    end

    # Loop through each line in the caller and see if the method we're watching is being called
    # This is needed due to the way TracePoint deals with inheritance
    def method_array
      parsed_array = kaller.map do |contents|
        code     = Ripper.sexp(contents)
        ::LetItGo::WTFParser.new(code)
      end
      parsed = parsed_array.detect do |parsed|
        parsed.each_method.any? { |m| m.method_name == method_name.to_s }
      end || []
    end

    def line_to_s
      @line_to_s ||= contents_from_file_line(file_name, line_number)
    end

    # Parses original method call location
    # Determines if a string literal was used or not
    def called_with_string_literal?(parser_klass = ::LetItGo::WTFParser)
      method_array.any? do |m|
        positions.any? {|position| m.arg_types[position] == :string_literal }
      end
    end

    def key
      "Method: #{klass}##{method_name} [#{kaller}]"
    end
  end


  # Call to begin watching method for frozen violations
  def self.watch_frozen(klass, method_name, positions:)
    @watching[klass] ||= {}
    @watching[klass][method_name] = positions
  end

  # If we are tracking it
  #   If it has positive counter
  #     Increment Counter
  #   If not
  #     do nothing
  # else we are not tracking it
  #   If it has a frozen string literal
  #     Set counter to 1
  #   If it does not
  #     Set counter to
  def self.watched_method_was_called(meth)
    if LetItGo.record_exists?(meth.key)
      if Thread.current[:let_it_go_records][meth.key] > 0
        LetItGo.increment(meth.key)
      end
    else
      if meth.called_with_string_literal?
        LetItGo.store(meth.key, 1)
      else
        LetItGo.store(meth.key, 0)
      end
    end
  end


  # Prevent looking
  def self.record_exists?(key)
    Thread.current[:let_it_go_records][key]
  end

  # Records when a method has been called without passing in a frozen object
  def self.store(key, increment = 0)
    @mutex.synchronize do
      Thread.current[:let_it_go_records][key] ||= 0
      Thread.current[:let_it_go_records][key] += increment
    end
  end

  def self.increment(key)
    store(key, 1)
  end

  # Turns hash of keys into a semi-inteligable sorted result
  class Report
    def initialize(hash_of_reports)
      @hash = hash_of_reports.reject {|k, v| v.zero? }.sort {|(k1, v1), (k2, v2)| v1 <=> v2 }.reverse
    end

    def count
      @hash.inject(0) {|count, (k, v)| count + v }
    end

    def report
      @report = "## Un-Fozen Hotspots (#{count} total)\n"
      @hash.each do |name_location, count|
        @report << "  #{count}: #{name_location}\n"
      end
      @report << "  (none)" if @hash.empty?
      @report << "\n"
      @report
    end

    def print
      puts report
    end
  end
end

require 'let_it_go/middleware/olaf'

Dir[File.expand_path("../let_it_go/core_ext/*.rb", __FILE__)].each do |file|
  require file
end

RubyVM::InstructionSequence.compile_option = { specialized_instruction: false }

TracePoint.trace(:call, :c_call) do |tp|
  tp.disable
  if LetItGo.recording?
    # puts "=="
    # puts tp.defined_class
    # puts tp.method_id
    # puts caller
    if positions = LetItGo.watching_positions(tp.defined_class, tp.method_id)
      meth = LetItGo::MethodCall.new(klass: tp.defined_class, method_name: tp.method_id, kaller: caller, positions: positions)
      LetItGo.watched_method_was_called(meth)
    end
  end
  tp.enable
end


# Tracepoint returns the original point of method definition, kinda makes sense
#
# TracePoint.trace(:end) do |tp|
#   tp.disable
#   ancestors = tp.self.ancestors
#   klasses = LetItGo.watching_klasses.select do |klass|
#     klass.is_a?(Class) ? ancestors.include?(klass) : tp.self.include?(klass)
#   end

#   klasses.each do |klass|
#     LetItGo.method_hash_for_klass(klass).each do |method, positions|
#       LetItGo.watch_frozen(tp.self, method, positions: positions)
#     end
#   end
#   tp.enable
# end


