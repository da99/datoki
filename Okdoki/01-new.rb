
require "./tests/helpers"
require "./Server/Okdoki/model"

class My_Model
  include Okdoki::Model
end

describe ":new" do

  it "returns an array mapped to models" do
    arr = My_Model.new [{id:1}, {id:2}]
    arr.size.should == 2
    arr.first.data[:id].should == 1
    arr.last.data[:id].should == 2
  end

  it "returns an object with data set to passed Hash" do
    o = My_Model.new id: 1
    o.data[:id].should == 1
  end

  it "raises Not_Found if args.size == 1, args.first == nil" do
    lambda {
      My_Model.new nil
    }.should.raise(My_Model::Not_Found)
    .message.should.match /My Model not found/
  end

end # === describe sdff ===
