require 'spec_helper'

describe LetItGo::Report do
  it 'reports' do
    report = LetItGo.record do
      load fixture("string.rb")
      load fixture("array.rb")
    end

    expected = <<-REPORT
## Un-Frozen Hotspots (5 total)

  3) #{ fixture("array.rb") }
    - 1) Array#join on line 3
    - 1) Array#join on line 2
    - 1) Array#join on line 1
  2) #{ fixture("string.rb") }
    - 2) String#gsub on line 2

REPORT

    expect(report.report).to eq(expected)
  end
end
