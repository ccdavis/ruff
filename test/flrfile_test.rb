


class FLRFileTest < Test::Unit::TestCase 
  
  

  def setup
    var_type = Struct.new(:name,:start,:len)
    
    # Split up your metadata by record type.
    
    @layouts = 
      {:household=>[var_type.new(:rectypeh,1,1), var_type.new(:phone,2,1), var_type.new("mortgage",3,1)],
        :person=>[var_type.new(:rectypep,1,1), var_type.new("age",2,3), var_type.new("sex",5,1), var_type.new("marst",6,1)]}
    
    # Give the values used in the data for each record type  
    @record_types ={"H"=>:household,"P"=>:person} 
  end
  
  def teardown
  end
  
  
  def test_initialize
  sample_data_path = File.dirname(__FILE__) 
  fwf = FLRFile.new(
        File.new("#{sample_data_path}/sample.dat"),
        @record_types, # Record types to read from the file, all others will be ignored 
        @layouts,# metadata for all record types
        1, # column  0 starts at logical location 1 
        {:household=>[:people],:person=>[:household_id,:pserial]} # extra columns by record type
        )
  
   # Extra columns + record_type accessors should have been created
     hh_struct = fwf.record_template[:household].record_structure.new
     assert hh_struct.respond_to?(:record_type),"household record should have record_type method"
     p_struct = fwf.record_template[:person].record_structure.new
     assert p_struct.respond_to?(:household_id),"Should have household_id as an extra column"
     assert p_struct.respond_to?(:record_type),"Should have record_type method"
   
  
  fwf = FLRFile.new(
          File.new("#{sample_data_path}/sample.dat"),
          @record_types, # Record types to read from the file, all others will be ignored 
          @layouts,# metadata for all record types
          1          )
          
          # Should still have added the record_type method but none of the others
          hh_struct = fwf.record_template[:household].record_structure.new
          assert hh_struct.respond_to?(:record_type),"Should have record_type method"
          assert !hh_struct.respond_to?(:people)  
  end
  
  def test_get_record_type
      sample_data_path = File.dirname(__FILE__) 
        fwf = FLRFile.new(
          File.new("#{sample_data_path}/sample.dat"),
          @record_types, # Record types to read from the file, all others will be ignored 
          @layouts,# metadata for all record types
          1, # column  0 starts at logical location 1 
          {:household=>[:people],:person=>[:household_id,:pserial]} # extra columns by record type
          )
      assert_nil fwf.get_record_type(nil)
      assert_equal :household,fwf.get_record_type("H123")
      assert_equal :person,fwf.get_record_type("P1234")
      assert_equal nil, fwf.get_record_type("C123") 
      
  end
  
  
  
  
  def test_build_record
    sample_data_path = File.dirname(__FILE__) 
      fwf = FLRFile.new(
      File.new("#{sample_data_path}/sample.dat"),
      @record_types, # Record types to read from the file, all others will be ignored 
      @layouts,# metadata for all record types
      1, # column  0 starts at logical location 1 
      {:household=>[:people],:person=>[:household_id,:pserial]} # extra columns by record type
      )
      
      assert_equal nil, fwf.build_record(nil)
      rec = fwf.build_record("H012345666665555444333")
      assert_equal :household,rec[:record_type]
      
      assert_raise RuntimeError do 
        fwf.build_record("c23abbbc")
      end
           
  end
  
  
  def test_each
    sample_data_path = File.dirname(__FILE__) 
     fwf = FLRFile.new(
       File.new("#{sample_data_path}/sample.dat"),
        @record_types, 
        @layouts,
        1,
        {:household=>[:record_type,:people],:person=>[:household_id,:pserial,:record_type]})
  
    records = []
  
  fwf.each do |record|
    records << record    
  end  
  assert records.first.respond_to?(:record_type)
  assert_equal :person, records.last.record_type  
  assert_equal :household,records[0].record_type
  assert_equal :person, records[1].record_type 
    
  end
  
  def test_next_record
    sample_data_path = File.dirname(__FILE__) 
    fwf = FLRFile.new(
      File.new("#{sample_data_path}/sample.dat"), # data is in this file
      @record_types, # Records of different types have these labels 
      @layouts, # metadata for creating record structs
      1, # All metadata starting column locations are to be shifted 1 left
      {:household=>[:people],:person=>[:household_id,:pserial]}) # Extra columns not to come from metadata
      
      records = []
      while rec = fwf.next_record do 
        records << rec

      end
      
      assert_equal :household, records.first.record_type 
      
  assert records.first.respond_to?(:record_type)
  
  # The last record is a person type and should not have a 'people' accessor
  assert !records.last.respond_to?(:people)
  
  # Should have added these accessors from the extra_columns argument above
  assert records.first.respond_to?(:people)
  assert records.last.respond_to?(:household_id)
  
  assert_equal :household,records[0].record_type
  assert_equal :person, records[1].record_type 
          
  end
  
  def test_open      
    record = Struct.new(:rectypeh,:phone,:mortgage,:record_type)
    
    sample_data_path = File.dirname(__FILE__) 
     FLRFile.open(
    "#{sample_data_path}/sample_out.dat", # data is in this file
    "w",# open file for writing
          @record_types, # Records of different types have these labels 
          @layouts, # metadata for creating record structs
          1)  do |fwf|# All metadata starting column locations are to be shifted 1 left            
          assert_equal FLRFile, fwf.class
          fwf << record.new("H",1,2,:household)
          fwf << ["H",1,3,:household]
          end
                           
     assert File.exists?("#{sample_data_path}/sample.dat") # data is in this file
     
     var = Struct.new(:name,:start,:len)
     l = {:customer=>[var.new("name",1,25),var.new("age",26,3)]}
     fwf = FLRFile.new(File.new("sample2_out.dat","w"),
         :customer, l,1) 
     
     fwf << ["joe",25,:customer]
     fwf.close
     
  end
  

def test_line_type
      sample_data_path = File.dirname(__FILE__) 
      fwf = FLRFile.new(
        File.new("#{sample_data_path}/sample.dat"),
        @record_types, # Record types to read from the file, all others will be ignored 
        @layouts,# metadata for all record types
        1, # column  0 starts at logical location 1 
        {:household=>[:people],:person=>[:household_id,:pserial]} # extra columns by record type
        )
  
  assert_equal :unknown, fwf.line_type(nil)
  assert_equal :household,fwf.line_type("H123")
  assert_equal :person,fwf.line_type("P123")
  assert_equal :unknown, fwf.line_type("C123")
end
  
  def test_get_next_known_line_type
    sample_data_path = File.dirname(__FILE__) 
      fwf = FLRFile.new(
          File.new("#{sample_data_path}/sample_activities.dat"),
          @record_types, # Record types to read from the file, all others will be ignored 
          @layouts,# metadata for all record types
          1, # column  0 starts at logical location 1 
          {:household=>[:people],:person=>[:household_id,:pserial]} # extra columns by record type
          )
  # By reading the sample_activities file with only the household and person record types know
  # we should get the activity and who records to be skipped.
  while rec=fwf.get_next_known_line_type 

    unless rec.strip.empty?

    assert ["P","H"].include?(rec[0..0])

      end
  end
  
  end
  
end
