require File.expand_path(File.dirname(__FILE__) + '/record_template')





class FLRFile  

  include Enumerable
  
  attr_reader :line_number, :record_template
  
  def initialize(source, record_types, record_layouts, logical_first_column=0, extra_columns = nil)
    # Allow record layouts like 
    # {:type1=>[:var1=>1..5,:var2=>7..8],:type2=>[:var1=>1..1,:var2=>3..4]}
    # ... todo
    @line_number = 0
    @file = source    
    @record_type_labels=record_types
    @record_type_symbols = record_types.is_a?(Hash) ? record_types.invert : :none
    if extra_columns  then
      @record_template = HFLR::RecordTemplate.create(record_layouts, @record_type_symbols, logical_first_column, extra_columns)   
    else
        @record_template = HFLR::RecordTemplate.create(record_layouts, @record_type_symbols, logical_first_column)   
    end        
  end

def finished?
  @file.eof?
end

def close
  @file.close
end

# If multiple record types,  extract it from the string, otherwise just return the type of this file
def get_record_type(line)
  return nil if line.nil?  
  return nil if line.strip.empty?
  @record_type_labels.is_a?(Hash) ? @record_type_labels[line[0..0]] : @record_type_labels       
end

def  build_record(line)    
  return nil if line.nil?        

  record_type = line_type(line)
  raise "Unknown record type at line #{@line_number.to_s}" if record_type == :unknown
  return @record_template[record_type].build_record(line.chomp)                 
end

def next_record
  @line_number += 1
  build_record(get_next_known_line_type) 
end

def line_type(line)
  record_type = get_record_type(line)
  return record_type ? record_type : :unknown
end

def get_next_known_line_type  
  line = @file.gets 
  record_type = line_type(line)
  while record_type == :unknown and (not finished?)
    line = @file.gets
    record_type = line_type(line)
  end
  record_type == :unknown ? nil : line
    
end

def each
  @file.each_line do |line|    
    @line_number += 1
    unless line_type(line) == :unknown       
      data = build_record(line)
      yield data 
    end
  end 
end

 # This will take a Hash or Struct orArray;  if an Array the record type must be the last element when 
 # the record layout  has more than one record type.
  def <<(record)         
    if record.is_a? Array
    record_type = @record_type_symbols == :none ? @record_template.keys.first : record.last     
      @file.puts @record_template[record_type].build_line(record)
    else
      record_type = @record_type_symbols == :none ?@record_template.keys.first : record[:record_type]
      if @record_template[record[:record_type]] == nil then
        raise "Record type problem in output: #{record[:record_type].to_s} type on record, #{@record_template.keys.join(",")} types of templates"
      end
      
      @file.puts @record_template[record_type].build_line(record)      
    end
  end

# Use when creating a new HFLR file
def self.open(path, mode, record_types, record_layouts, logical_first_column=0)  
  file = File.open(path, mode)
  begin
    hflr_file = new(file, record_types, record_layouts, logical_first_column) 
    yield hflr_file
  ensure
    file.close
  end
end
  
end
