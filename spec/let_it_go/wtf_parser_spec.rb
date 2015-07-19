require 'spec_helper'

describe LetItGo::WTFParser do
  it 'works for simple cases' do
    code = <<-CODE
      "foo".gsub(//, "blerg")
    CODE

    ripped_code = Ripper.sexp(code)
    parser      = LetItGo::WTFParser.new(ripped_code)

    arg_types = parser.each_method.map {|x| x.arg_types }
    expect(arg_types).to eq([[:regexp_literal, :string_literal]])

    names     = parser.each_method.map {|x| x.method_name }
    expect(names).to eq(["gsub"])
  end


  it "doesn't return a :string_literal for modified strings" do
    code = <<-CODE
      "foo".gsub(//, "blerg".downcase)
    CODE

    ripped_code = Ripper.sexp(code)
    parser    = LetItGo::WTFParser.new(ripped_code)

    arg_types = parser.each_method.map {|x| x.arg_types }
    expect(arg_types).to eq([[:regexp_literal, :call]])
  end

  it "handles nested method calls cases" do
    code = <<-CODE
      "foo".gsub(//, "bar".gsub!(//, "zoo"))
    CODE

    ripped_code = Ripper.sexp(code)
    parser    = LetItGo::WTFParser.new(ripped_code)

    arg_types = parser.each_method.map {|x| x.arg_types }
    expect(arg_types).to eq([[:regexp_literal, :call], [:regexp_literal, :string_literal]])
  end


  it "handles nested method calls in nested method calls" do
    code = <<-CODE
      "foo".gsub(//, "bar".gsub!(//, "zoo".gsub(//, "blah")))
    CODE

    ripped_code = Ripper.sexp(code)
    parser      = LetItGo::WTFParser.new(ripped_code)

    arg_types = parser.each_method.map {|x| x.arg_types }
    expect(arg_types).to eq([[:regexp_literal, :call], [:regexp_literal, :call], [:regexp_literal, :string_literal]])
  end

  it "handles methodcalls nested inside of other data structures" do
    code = <<-CODE
      [key.strip, value.gsub(/^"|"$/,'')]
    CODE

    ripped_code = Ripper.sexp(code)
    parser      = LetItGo::WTFParser.new(ripped_code)

    arg_types = parser.each_method.select {|x| x.method_name == "gsub" }.map(&:arg_types)

    expect(arg_types).to eq([[:regexp_literal, :string_literal]])
  end

  it "handles chained method calls" do
    code = <<-CODE
      value.downcase.gsub(/^"|"$/,'').delete('')
    CODE

    ripped_code = Ripper.sexp(code)
    parser      = LetItGo::WTFParser.new(ripped_code)
    arg_types = parser.each_method.select {|x| x.method_name == "gsub" }.map(&:arg_types)

    expect(arg_types).to eq([[:regexp_literal, :string_literal]])

  end

  it "any?" do
    code = <<-CODE
      "foo".gsub //, "blerg".downcase
    CODE

    ripped_code = Ripper.sexp(code)
    parser      = LetItGo::WTFParser.new(ripped_code)

    has_gsub = parser.each_method.any? {|x| x.method_name == "gsub" }
    expect(has_gsub).to eq(true)

    has_first = parser.each_method.any? {|x| x.method_name == "first" }
    expect(has_first).to eq(false)

  end

  it "no parens" do
    code = <<-CODE
      "foo".gsub //, "blerg".downcase
    CODE

    ripped_code = Ripper.sexp(code)
    parser      = LetItGo::WTFParser.new(ripped_code)

    arg_types = parser.each_method.select {|x| x.method_name == "gsub" }.map(&:arg_types)

    expect(arg_types).to eq([[:regexp_literal, :call]])

    code = <<-CODE
      "foo".gsub //, "blerg"
    CODE

    ripped_code = Ripper.sexp(code)
    parser      = LetItGo::WTFParser.new(ripped_code)

    arg_types = parser.each_method.select {|x| x.method_name == "gsub" }.map(&:arg_types)

    expect(arg_types).to eq([[:regexp_literal, :string_literal]])
  end


  it "include?" do
    code = <<-CODE
      [].include?("foo")
    CODE

    ripped_code = Ripper.sexp(code)
    parser      = LetItGo::WTFParser.new(ripped_code)
    arg_types = parser.each_method.select {|x| x.method_name == "include?" }.map(&:arg_types)

    expect(arg_types).to eq([[:string_literal]])
  end

  it "implicit methods" do
    # pending("Parsing a parsed output is hard")

    code = <<-CODE
      "hello" + "there"
    CODE

    ripped_code = Ripper.sexp(code)

    pp ripped_code
    parser      = LetItGo::WTFParser.new(ripped_code)
    arg_types = parser.each_method.select {|x| x.method_name == "+" }.map(&:arg_types)

    expect(arg_types).to eq([[:string_literal]])
  end

  it "implicit receiver" do
    code = <<-CODE
      foo("hello")
    CODE

    ripped_code = Ripper.sexp(code)

    pp ripped_code
    parser      = LetItGo::WTFParser.new(ripped_code)
    arg_types = parser.each_method.select {|x| x.method_name == "foo" }.map(&:arg_types)

    expect(arg_types).to eq([[:string_literal]])
  end

end



