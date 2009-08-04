		


class RecordTemplateTest < Test::Unit::TestCase
   
  
	  Var = Struct.new(:name,:start,:len)
  
  # Some real world metadata. This is only layout for the starting portion of the ATUS / CPS household record
  # which actually extends to beyond column 117
  AtusHH =[[:RECTYPEH,	1,	1,],
[:CASEID,	2,	14],
[:AGEYCHILD,	16,	3],
[:SERIAL,	19,	7],
[:HH_NUMADULTS,	26,	2],
[:FAMBUS_RESP,	28,	2],
[:FAMBUS_OTHER,	30,	2],
[:FAMBUS_SPOUSE,	32,	2],
[:FAMBUS,	34,	2],
[:HH_CHILD,	36,	2],
[:HH_NUMKIDS,	38,	2],
[:HH_SIZE,	40,	3],
[:HH_NUMEMPLD,	43,	3],
[:FAMINCOME,	46,	3]]


  
  def setup      
    
    hh_vars = AtusHH.map{|v| Var.new(v[0],v[1],v[2])}

  @vars = {:household=>hh_vars,
  :person=>[Var.new("age",2,3),Var.new("sex",5,1)],
  :activity=>[Var.new("where",1,5),Var.new("activity",6,5)],
  :who=>[Var.new("relatew",1,2)]}
  @record_types = {"H"=>:household,"P"=>:person,"A"=>:activity,"W"=>:who} 
  @record_type_symbols = @record_types.invert
  end  
  
 def  test_create
   record_layouts = @vars # variables by record type
   templates = HFLR::RecordTemplate.create(record_layouts, @record_type_symbols, 1)
   assert_equal @vars.keys, templates.keys
   
   household_field_pattern =  templates[:household].field_pattern
   person_field_pattern =templates[:person].field_pattern
   activity_field_pattern = templates[:activity].field_pattern
   who_field_pattern = templates[:who].field_pattern
   
   
   assert household_field_pattern.is_a?(String)
   assert person_field_pattern.size>2,"field pattern should have at least one variable"
   assert activity_field_pattern.size>2,"field pattern for activity should have at least one variable"
   assert who_field_pattern.size>2,"field pattern for who should have at least one variable"
   
   
   household_record_struct = templates[:household].record_structure.new
   assert household_record_struct.respond_to?(:HH_SIZE)
  
 end
 
 def test_create_template_class
   template = HFLR::RecordTemplate.create_template_class(:person,@record_type_symbols[:person], @vars[:person],1,{})
   assert template.respond_to?(:field_pattern)
   assert template.respond_to?(:record_structure)
   record_structure = template.record_structure
  assert record_structure.new.is_a?(Struct)
  assert record_structure.new.respond_to?(:record_type)
   
 end
 
 
 def test_get_pattern
    household_layout = @vars[:household]
    
    pattern = HFLR::RecordTemplate.get_pattern(household_layout)
    assert_equal "@1A1",pattern[0..3]
    
    # Adjust the location ('@') leftward (the metadata refers to the 0th column as column 1.)
    pattern = HFLR::RecordTemplate.get_pattern(household_layout,1)
    assert_equal "@0A1",pattern[0..3]
    
    vars_in_pattern = pattern.scan("A").size 
    assert_equal household_layout.size, vars_in_pattern
         
 end

def test_build_record
  templates = HFLR::RecordTemplate.create(@vars,@record_type_symbols,1)
  hh_str = "1200501010500069980000001020000000000000020009960200009999999999999999991330299902305030201034300000000037110550997797000000000007700100000000200411000000000"  
  
  # from a string to a record struct
  household_rec = templates[:household].build_record(hh_str)
    
  assert household_rec.is_a?(Struct)
  assert household_rec.values.size> @vars[:household].size,"Should be values for the extra columns"
  
  # Check a few things...
  assert_equal 1,household_rec[:SERIAL].to_i
  

  assert_equal 1,household_rec.SERIAL.to_i
  
  assert_equal "1",household_rec[0]
  assert_equal "1",household_rec.RECTYPEH
  assert_equal "1",household_rec[:RECTYPEH]
  
  

  end
  
  def test_build_line
  templates = HFLR::RecordTemplate.create(@vars,@record_type_symbols,1)

    hh_str = "H200501010500069980000001020000000000000020009960200009999999999999999991330299902305030201034300000000037110550997797000000000007700100000000200411000000000"  
    
    # from a string to a record struct
    household_rec = templates[:household].build_record(hh_str)
    assert_equal "002",hh_str[39..41]    
    assert_equal "002",household_rec.HH_SIZE

    
    # back to a string
    new_hh_str = templates[:household].build_line(household_rec)
    
       
    assert_equal "002",new_hh_str[39..41]
    
    # Some of the values in hh_str won't be in new_hh_str because not all data
    # in hh_str is mapped by household_layout, but the mapped variables should have
    # the same values.
    
    @vars[:household].each do |v|
      format_str = "@#{(v.start-1).to_s}a#{v.len.to_s}" 
      orig_data = hh_str.unpack(format_str) 
      new_data = new_hh_str.unpack(format_str)
    
   
      assert_equal new_data, orig_data,"Comparing #{v.name} #{format_str}" 
    end       
  end
  
  
  def test_format_fields
    templates = HFLR::RecordTemplate.create(@vars,@record_type_symbols,1)
    
    formatted_fields = templates[:who].send(:format_fields,[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15])
    
    widths = @vars[:who].map{|v| v.len}
    formatted_fields.size.times do |i|
      assert_equal formatted_fields[i].size, widths[i],"Width of #{@vars[:who][i].name} should have been #{widths[i].to_s}" 
    end
    
  end
  
  def test_write_format    
   templates = HFLR::RecordTemplate.create(@vars,@record_type_symbols,1)
   
   assert_equal "abc",templates[:activity].send(:right_format,"abc",3)
   assert_equal "abc   ",templates[:activity].send(:right_format,"abc",6)
    assert_equal "3",templates[:activity].send(:right_format,3,1)
    assert_equal "005",templates[:activity].send(:right_format,5,3)
    assert_equal "ZZZ",templates[:activity].send(:right_format,-999998,3)
  end
  
  
   
end
 
 
 
 
 

