require 'spec_helper'

describe "Array#" do

  it 'index' do
    report = LetItGo.record do
      [].index("")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      [].index("".freeze)
    end
    expect(report.count).to eq(0)
  end

  it 'fill' do
    report = LetItGo.record do
      [].fill("")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      [].fill("".freeze)
    end
    expect(report.count).to eq(0)
  end

  it 'fetch' do
    report = LetItGo.record do
      [].fetch(1, "")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      [].fetch(1, "".freeze)
    end
    expect(report.count).to eq(0)
  end

  it 'delete' do
    report = LetItGo.record do
      [].delete("")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      [].delete("".freeze)
    end
    expect(report.count).to eq(0)
  end

  it 'count' do
    report = LetItGo.record do
      [].count("")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      [].count("".freeze)
    end
    expect(report.count).to eq(0)
  end

  it 'assoc' do
    report = LetItGo.record do
      [].assoc("")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      [].assoc("".freeze)
    end
    expect(report.count).to eq(0)
  end

  it 'include?' do
    report = LetItGo.record do
      [].include?("")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      [].include?("".freeze)
    end
    expect(report.count).to eq(0)
  end

  it 'join' do
    report = LetItGo.record do
      [].join("")
    end
    expect(report.count).to eq(1)

    report = LetItGo.record do
      [].join("".freeze)
    end
    expect(report.count).to eq(0)
  end
end
