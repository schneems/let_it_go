module LetItGo

  # Turns hash of keys into a semi-inteligable sorted result
  class Report
    def initialize(hash_of_reports)
      @hash = hash_of_reports.reject {|k, obj| obj.zero? }
    end

    def count
      @hash.inject(0) {|count, (_k, obj)| count + obj.count; }
    end

    def report
      @report = "## Un-Frozen Hotspots (#{count} total)\n\n"

      file_names = @hash.values.map(&:file_name).uniq
      file_name_hash = Hash.new { [] }
      file_names.each do |name|
        file_name_hash[name] = @hash.select {|_, obj| obj.file_name == name}.values.sort {|obj1, obj2| obj1.count <=> obj2.count }.reverse
      end

      file_name_hash = file_name_hash.sort {|(_, objects1), (_, objects2) |
        count1 = objects1.inject(0) {|count, obj| count + obj.count }
        count2 = objects2.inject(0) {|count, obj| count + obj.count }
        count1 <=> count2
        }.reverse

      file_name_hash.each do |file_name, objects|
        count = objects.inject(0) {|sum, obj| sum + obj.count }
        @report << "  #{count}) #{file_name}\n"
        objects.each do |obj|
          @report << "    - #{obj.count}) #{obj.klass}##{obj.method_name} on line #{ obj.line_number }\n"
        end
      end

      @report << "  (none)" if @hash.empty?
      @report << "\n"
      @report
    end

    def print
      puts report
    end
  end
end
