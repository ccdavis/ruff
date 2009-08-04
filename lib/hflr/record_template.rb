
module HFLR

class RecordTemplate
    UnfilledChar = ' '
    MissingOutput = "ZZZZZZZZZZZZZZZZZZZZZ"
  
  attr_reader :record_structure, :field_pattern,:record_type,:record_type_label
  attr_accessor :strip_whitespace
    
  def initialize(record_type, record_type_label, record_structure,field_pattern, field_widths)
    @record_type = record_type    
    @record_type_label = record_type_label
    @record_structure = record_structure
    @field_pattern = field_pattern
    @field_widths = field_widths
  end
  
# Layouts is a hash of variables by record type
# record_type_symbols maps record type names to their labels in the data {:household=>"H",:person=>"P"}
# Returns a set of record templates, one for each record type  
def self.create(record_layouts, record_type_symbols, first_column_location, extra_columns=[])    
   extra_columns = empty_extra_columns(record_layouts.keys) if  extra_columns.is_a? Array    
  templates = {}
  self.check_record_layouts(record_layouts)
  
  record_layouts.keys.each do |record_type|    
    record_label = record_type_symbols == :none ? :none : record_type_symbols[record_type]
    templates[record_type] = 
    self.create_template_class(record_type,
      record_label,
    record_layouts[record_type], 
    first_column_location, 
    extra_columns[record_type]) 
  end
  return templates  
end

private
  # If the name exists already do not replace it, but add extra columns not to be mapped by the unpack field patterns
  # and ensure the record_type variable is added.
  # Since 'record_type' may not be in the metadata we don't want to map it to a 
  # specific column location but do want it included always.
  def self.add_extra_columns(names, extra)
    new_names = names.dup
    # names are not case sensitive
    extra.each{|n|new_names << n unless names.map{|m| m.to_s.upcase}.include? n.to_s.upcase}
    	    
    # No matter what, include 'record_type'
    unless new_names.map{|n| n.to_s.upcase}.include?("RECORD_TYPE")
      new_names << :record_type
    end   
    return new_names
  end
  
  def self.get_pattern(layout, first_column_location=0)     
    layout.map {|l| '@' + (l.start - first_column_location).to_s + 'A' + l.len.to_s}.to_s
  end

public

  def build_record(line)    
    rec = line.unpack(@field_pattern)            
    rec.map{|f| f.strip!} if @strip_whitespace
    begin
      data = self.record_structure.new(*rec)              
      data[:record_type] = @record_type
    rescue Exception=>msg
        raise "On record type #{self.record_type} problem with structure " + msg.to_s
    end
    return data
  end
    
  def build_line(record)            
    line = format_fields(record).pack(@field_pattern)
    line[0] = @record_type_label unless @record_type_label == :none
    line.tr!("\0",UnfilledChar)  
    return line
  end

private

def self.empty_extra_columns(record_types)
  extra = {}
  record_types.map{|rt| extra[rt] = []}
  extra
end

# All starting columns must be in order
def self.check_record_layouts(layouts)
  layouts.values.each do |layout|
    last_v = layout.first
    layout.each do |v|
      if v.respond_to?(:rectype) then
      if last_v.rectype != v.rectype
        raise "record type mismatch between #{v.name} and #{last_v.name}"
      end
    end  
      if last_v.start<= v.start then
        last_v = v
      else
        raise "Problem with start columns #{last_v.name} start #{last_v.start.to_s}  out of sequence with #{v.name} starting at #{v.start.to_s}"
      end
    end
  end
end

def self.create_template_class(record_type, record_type_label, layout, first_column_location, extra_columns = nil)
  names = layout.map {|l| l.name.to_sym}
  names = add_extra_columns(names, extra_columns) 
  structure = Struct.new(*names)
  return new(record_type, 
    record_type_label,
    structure,
    self.get_pattern(layout, first_column_location),
    layout.map{|v| v.len})
  end
  
    
  def format_fields(record)
   if record.is_a?(Array) or record.is_a?(Struct) then
     fields = []    
     @field_widths.each_with_index do |width, i|  
    fields << right_format(record[i], width)
   end
  return fields
 else
   raise "Record to format must be a Struct or Array"
  end
end
           
  def right_format(data, len)
    data_str = ""
    if data.is_a? String
      data_str = data.ljust(len)
    elsif data.is_a? Symbol 
     data_str = data.to_s.ljust(len)
    else
     data_str = sprintf("%0#{len.to_s}d",data)
     data_str = MissingOutput[0..len-1] if data == -999998
  end
    raise "Data too large for allocated columns #{data_str}" if data_str.size > len
    data_str
  end
      

end # RecordTemplate class

end # HFLR module

