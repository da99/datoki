

describe 'record_errors' do

  it "prevents failing with an exception" do
    r = Class.new {
      include Datoki
      record_errors
      field(:title) { varchar }
    }.create

    r.errors.should == {:title=>{:msg=>'Title is required.', :value=>nil}}
  end

end # === describe record_errors ====================================
