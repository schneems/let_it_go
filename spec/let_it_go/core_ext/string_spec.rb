require 'spec_helper'

describe "String#" do

  it "concat" do
    report = LetItGo.record do
      "".concat ","
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      "".concat ",".freeze
    end
    expect(report.count).to eq(0)
  end

  it "<=>" do
    pending("Parsing imlicit method calls with WTFParser")
    report = LetItGo.record do
      "" << ","
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      "" << ",".freeze
    end
    expect(report.count).to eq(0)
  end

  it "<<" do
    pending("Parsing imlicit method calls with WTFParser")
    report = LetItGo.record do
      "" << ","
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      "" << ",".freeze
    end
    expect(report.count).to eq(0)
  end

  it "+" do
    pending("Parsing imlicit method calls with WTFParser")
    report = LetItGo.record do
      "" + ","
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      "" + ",".freeze
    end
    expect(report.count).to eq(0)
  end

  it "split" do
    report = LetItGo.record do
      "".split(",")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      "".split(",".freeze)
    end
    expect(report.count).to eq(0)
  end

  it "gsub[0]" do
    report = LetItGo.record do
      "".gsub("", "".freeze)
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      "".gsub("".freeze, "".freeze)
    end
    expect(report.count).to eq(0)
  end

  it 'gsub[1]' do
    report = LetItGo.record do
      "".gsub(//, "")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      "".gsub(//, "".freeze)
    end
    expect(report.count).to eq(0)
  end
end
