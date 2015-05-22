require 'ripper'
require 'pp'
require 'thread'

require "let_it_go/version"

module LetItGo
end

require 'let_it_go/wtf_parser'

module LetItGo
  DEFAULT_PARSE_SOURCE = true
  @mutex               = Mutex.new

  # Main method, wrap code you want to check for frozen violations in
  # a `let_it_go` block.
  #
  # By default it will try to parse source of the method call to determine
  # if a string literal or variable was used. We only care about string literals.
  def self.record(parse_source: DEFAULT_PARSE_SOURCE)
    @mutex.synchronize do
      Thread.current[:let_it_go_parse_source] = parse_source
      Thread.current[:let_it_go_recording]    = :on
      Thread.current[:let_it_go_records]      = {}
    end
    yield
    records = Thread.current[:let_it_go_records]
    report  = Report.new(records)
    return report
  ensure
    @mutex.synchronize do
      Thread.current[:let_it_go_parse_source] = nil
      Thread.current[:let_it_go_recording]    = nil
      Thread.current[:let_it_go_records]      = nil
    end
  end

  class << self
    alias :cant_hold_it_back_anymore :record
    alias :do_you_want_to_build_a_snowman :record
    alias :turn_away_and_slam_the_door :record
    alias :the_cold_never_bothered_me_anyway :record
    alias :let_it_go :record
  end

  def self.skip_source_parse?
    !Thread.current[:let_it_go_parse_source]
  end

  def self.recording?
    Thread.current[:let_it_go_recording] == :on
  end

  # Wraps logic that require knowledge of the method call
  # can parse original method call's source and determine if a string literal
  # was passed into the method.
  class MethodCall
    attr_accessor :line_number, :file_name, :klass, :method_name, :kaller
    def initialize(klass: , method_name: , kaller:)
      @klass        = klass
      @method_name  = method_name
      @kaller       = kaller

      file_line       = kaller.split(":in `".freeze).first # can't use gsub, because global variables get messed up
      file_line_array = file_line.split(":".freeze)

      @line_number = file_line_array.pop
      @file_name   = file_line_array.join(":".freeze)
    end

    def line_to_s
      @line_to_s ||= begin
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

    # Parses original method call location
    # Determines if a string literal was used or not
    def called_with_string_literal?(positions, parser_klass = ::LetItGo::WTFParser)
      return true if line_to_s.nil?

      if parsed_code = Ripper.sexp(line_to_s)
        parser_klass.new(parsed_code).each_method.any? do |m|
          m.method_name == method_name.to_s && positions.any? {|position| m.arg_types[position] == :string_literal }
        end
      end
    end

    def key
      "Method: #{klass}##{method_name} [#{kaller}]"
    end
  end

  # Call to begin watching method for frozen violations
  def self.watch_frozen(klass, method_name, positions:)
    original = klass.instance_method(method_name)
    klass.send(:define_method, method_name) do |*args, &block|
      if LetItGo.recording?
        if positions.any? {|position| args[position].is_a?(String) && !args[position].frozen? }
          meth = MethodCall.new(klass: klass, method_name: method_name, kaller: caller.first )
          if LetItGo.record_exists?(meth.key) || LetItGo.skip_source_parse? || meth.called_with_string_literal?(positions)
            LetItGo.store(meth.key)
          end
        end
      end
      original.bind(self).call(*args, &block)
    end
  end

  # Prevent looking
  def self.record_exists?(key)
    Thread.current[:let_it_go_records][key]
  end

  # Records when a method has been called without passing in a frozen object
  def self.store(key)
    @mutex.synchronize do
      Thread.current[:let_it_go_records][key] ||= 0
      Thread.current[:let_it_go_records][key] += 1
    end
  end

  # Turns hash of keys into a semi-inteligable sorted result
  class Report
    def initialize(hash_of_reports)
      @hash = hash_of_reports.sort {|(k1, v1), (k2, v2)| v1 <=> v2 }.reverse
    end

    def count
      @hash.inject(0) {|count, (k, v)| count + v }
    end

    def report
      @report = "## Un-Fozen Hotspots\n"
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

