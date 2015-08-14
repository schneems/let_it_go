require 'spec_helper'

describe "String#" do

  it "concat" do
    report = LetItGo.record do
      a = "foo"
      a.concat ","
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      a = "foo"
      a.concat ",".freeze
    end
    expect(report.count).to eq(0)
  end

  it "<=>" do
    report = LetItGo.record do
      a = "foo"
      a << ","
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      a = "foo"
      a << ",".freeze
    end
    expect(report.count).to eq(0)
  end

  it "<<" do
    report = LetItGo.record do
      a = "foo"
      a << ","
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      a = "foo"
      a << ",".freeze
    end
    expect(report.count).to eq(0)
  end

  it "+" do
    report = LetItGo.record do
      a = "foo"
      a + ","
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      a = "foo"
      a + ",".freeze
    end
    expect(report.count).to eq(0)
  end

  it "split" do
    report = LetItGo.record do
      a = "foo"
      a.split(",")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      a = "foo"
      a.split(",".freeze)
    end
    expect(report.count).to eq(0)
  end

  it "gsub[0]" do
    report = LetItGo.record do
      a = "foo"
      a.gsub("", "".freeze)
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      a = "foo"
      a.gsub("".freeze, "".freeze)
    end
    expect(report.count).to eq(0)
  end

  it 'gsub[1]' do
    report = LetItGo.record do
      a = "foo"
      a.gsub(//, "")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      a = "foo"
      a.gsub(//, "".freeze)
    end
    expect(report.count).to eq(0)
  end

  it '==' do
    report = LetItGo.record do
      a = ""
      a == ""
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      "" == "".freeze
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      a = ""
      a == "".freeze
    end
    expect(report.count).to eq(0)



  end
end
