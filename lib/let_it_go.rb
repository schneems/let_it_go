require 'ripper'
require 'pp'
require 'thread'

require "let_it_go/version"

module LetItGo
end

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


  # Call to begin watching method for frozen violations
  def self.watch_frozen(klass, method_name, positions:, receiver: false)
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
    unless method = Thread.current[:let_it_go_records][meth.key]
      Thread.current[:let_it_go_records][meth.key] = method = meth
    end

    if method.optimizable?
      # puts method.inspect
      # puts method.string_allocation_count

      method.call_count += 1
      # puts method.call_count
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
end

require 'let_it_go/middleware/olaf'
require 'let_it_go/caller_line'
require 'let_it_go/method_call'
require 'let_it_go/report'


Dir[File.expand_path("../let_it_go/core_ext/*.rb", __FILE__)].each do |file|
  require file
end

RubyVM::InstructionSequence.compile_option = { specialized_instruction: false }

TracePoint.trace(:call, :c_call) do |tp|
  tp.disable
  if LetItGo.recording?
    if positions = LetItGo.watching_positions(tp.defined_class, tp.method_id)
      meth = LetItGo::MethodCall.new(klass: tp.defined_class, method_name: tp.method_id, kaller: caller, positions: positions)
      LetItGo.watched_method_was_called(meth)
    end
  end
  tp.enable
end


