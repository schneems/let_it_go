require 'spec_helper'

describe LetItGo do
  it 'has a version number' do
    expect(LetItGo::VERSION).not_to be nil
  end

  it 'records string literal method calls' do
    report = LetItGo.record do
      "foo".gsub //, "blerg"
    end
    expect(report.count).to eq(1)
  end

  it 'does does not report non-string literals' do
    report = LetItGo.record do
      "foo".gsub //, "blerg".downcase
    end
    expect(report.count).to eq(0)
  end

  it "allows block methods to be called" do
    report = LetItGo.record do
      "foo".sub(/[f]/) { |match| match.downcase }
    end

    report = LetItGo.record do
      "foo".sub(/[f]/) { $&.upcase }
    end
    expect(report.count).to eq(0)
  end

  class Foo
    def split(string)
    end
  end

  it "traces subclasses" do
    LetItGo.watch_frozen(Foo, :split, positions: [0])
    class Zomg < Foo; end

    puts "STARTTTTTT"
    report = LetItGo.record do
      Zomg.new.split("")
    end
    puts "DONEEEEEEE"

    expect(report.count).to eq(1)

    anon_class = Class.new(Foo)
    report = LetItGo.record do
      anon_class.new.split("")
    end

    expect(report.count).to eq(1)
  end
end
