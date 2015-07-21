$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'let_it_go'


require 'pathname'

def fixture(name)
  Pathname.new(File.expand_path("../fixtures", __FILE__)).join(name)
end
