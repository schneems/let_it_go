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

  it "accepts options, has source enabled by default" do
    report = LetItGo.record(parse_source: false) do
      "foo".gsub //, "blerg".downcase
    end
    expect(report.count).to eq(1)
  end

  it "allows block methods to be called" do
    report = LetItGo.record(parse_source: false) do
      "foo".sub(/[f]/) { |match| match.downcase }
    end

    report = LetItGo.record(parse_source: false) do
      "foo".sub(/[f]/) { $&.upcase }
    end
    expect(report.count).to eq(0)
  end
end
