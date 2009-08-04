require File.dirname(__FILE__) + "/../lib/hflr"


# Read a file with only one record type (no record type markers)

# metadata for customer file
Column = Struct.new(:name,:start,:len)
columns = {:customer=>[
Column.new("name",1,25),
Column.new("zip",26,5),
Column.new("balance",31,5)]}
  
customer_file = FLRFile.new(File.new("customers.dat"), :customer, columns, 1, [:line_number])


# You can read through the file and access the fields with methods named after the columns:
customer_file.each do |record|
  puts "Customer #{customer_file.line_number.to_s} #{record.name} #{record.zip} "
end


# You can get the values by attribute name like a hash
def show(record)
  print record.members.map{|m| m.to_s + ": " + record[m].to_s}.join(", ") + "\n" 
  end

# metadata for customer_orders file
layouts = {:customer=>[
  Column.new("name",1,25),
  Column.new("zip",26,5),
  Column.new("balance",31,5)],  
:order=>[
  Column.new("order_num",1,8),
  Column.new("date",9,10),]}
  
  
customer_orders_file = FLRFile.new(
  File.new("customer_orders.dat"), 
  {"C"=>:customer,"O"=>:order},# Use these characters as record type markers 
  layouts, 
  0, # shift parsed string 0 columns to the left of the indicated start column 
  {:customer=>[:line_number,:record_type],:order=>[:line_number,:record_type]}) # Add these columns to the indicated record types post read
  
  
  customer_orders_file.each do |record|
    show record
  end
  
  
  