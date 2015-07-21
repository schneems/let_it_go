module LetItGo
  # Given a single line from `caller` retrieves line_number, file_name
  # and can read the contents of the file
  class CallerLine
    attr_accessor :line_number, :file_name
    def initialize(string)
      file_line       = string.split(":in `".freeze).first
      file_line_array = file_line.split(":".freeze)

      @line_number = file_line_array.pop
      @file_name   = file_line_array.join(":".freeze) # name may have `:` in it
    end

    def contents
      @contents ||= read || ""
    end

  private
    def read
      contents = ""
      File.open(file_name).each_with_index do |line, index|
        next unless index == Integer(line_number).pred
        contents = line
        break
      end
      contents
    rescue Errno::ENOENT
      nil
    end
  end
end