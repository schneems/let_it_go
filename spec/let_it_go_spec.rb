require 'spec_helper'

describe LetItGo do
  it 'has a version number' do
    expect(LetItGo::VERSION).not_to be nil
  end

  it 'records string literal method calls' do
    report = LetItGo.record do
      a = "foo"
      a.gsub //, "blerg"
    end
    expect(report.count).to eq(1)
  end

  it 'does does not report non-string literals' do
    report = LetItGo.record do
      a = "foo"
      a.gsub //, "blerg".downcase
    end
    expect(report.count).to eq(0)
  end

  it "allows block methods to be called" do
    report = LetItGo.record do
      a = "foo"
      a.sub(/[f]/) { |match| match.downcase }
    end

    report = LetItGo.record do
      a = "foo"
      a.sub(/[f]/) { $&.upcase }
    end
    expect(report.count).to eq(0)
  end


  it "traces subclasses" do
    class TracesSubclass
      def split(string)
      end
    end

    LetItGo.watch_frozen(TracesSubclass, :split, positions: [0])

    class ZomgTraceSubclass < TracesSubclass; end
    report = LetItGo.record do
      ZomgTraceSubclass.new.split("")
    end

    expect(report.count).to eq(1)

    anon_class = Class.new(TracesSubclass)
    report = LetItGo.record do
      anon_class.new.split("")
    end

    expect(report.count).to eq(1)
  end



  it "traces modules" do
    module TracesModule
      def split(string)
      end
    end

    LetItGo.watch_frozen(TracesModule, :split, positions: [0])
    class ZomgTraceModule; include TracesModule; end
    report = LetItGo.record do
      ZomgTraceModule.new.split("")
    end

    expect(report.count).to eq(1)

    m = Module.new
    m.extend TracesModule

    report = LetItGo.record do
      m.split("")
    end

    expect(report.count).to eq(1)
  end

  it "counts multiple string allocations per line" do
    report = LetItGo.record do
      a = "foo"
      a.gsub "bloop", "blerg"
    end
    expect(report.count).to eq(2)
  end

end
