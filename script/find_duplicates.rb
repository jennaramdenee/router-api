require 'google_drive'

class DuplicatesSpreadsheet
  USERNAME = "user@example.com"
  PASSWORD = "super_secret"
  SPREADSHEET_NAME = "Route_duplicates"

  def initialize(spreadsheet_name = SPREADSHEET_NAME)
    @spreadsheet_name = spreadsheet_name
  end

  def worksheet
    return @worksheet if @worksheet
    session = GoogleDrive.login(USERNAME, PASSWORD)
    @worksheet = session.file_by_title(@spreadsheet_name).worksheets[0]
  end

  def populate_duplicate_data(duplicates)
    path_indices = existing_path_indices
    next_free_row = worksheet.num_rows + 1
    duplicates.each do |(prefix, exact)|
      unless row_num = path_indices[prefix.incoming_path]
        puts "New row #{prefix.incoming_path}"
        row_num = next_free_row
        next_free_row += 1
      end
      worksheet[row_num, 1] = prefix.incoming_path
      worksheet[row_num, 4] = prefix.handler
      worksheet[row_num, 5] = exact.handler
      worksheet[row_num, 6] = (prefix.handler == "backend" ? prefix.backend_id : "")
      worksheet[row_num, 7] = (exact.handler == "backend" ? exact.backend_id : "")
      worksheet[row_num, 8] = (prefix.handler == "redirect" ? prefix.redirect_to : "")
      worksheet[row_num, 9] = (exact.handler == "redirect" ? exact.redirect_to : "")
    end
    puts "Saving spreadsheet"
    worksheet.save
  end

  def existing_path_indices
    indices = {}
    worksheet.rows.each_with_index do |row, i|
      next if i <= 1 # Skip header rows 1 and 2
      indices[row[0]] = i + 1 # We want a 1-indexed result
    end
    indices
  end

end

def matching_routes?(a, b)
  return false unless a.handler == b.handler
  case a.handler
  when "backend"
    return a.backend_id == b.backend_id
  when "redirect"
    return a.redirect_to == b.redirect_to &&
      a.redirect_type == b.redirect_type
  else
    return true
  end
end

duplicates = []

puts "Finding duplicate routes"
Route.where(:route_type => "prefix").asc(:incoming_path).each do |prefix|
  exact = Route.where(:route_type => "exact", :incoming_path => prefix.incoming_path).first
  next unless exact
  next if matching_routes?(prefix, exact)
  duplicates << [prefix, exact]
end

puts "Updating Google Spreadsheet"
DuplicatesSpreadsheet.new.populate_duplicate_data(duplicates)
