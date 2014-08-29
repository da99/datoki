
describe Doki do

  it "runs" do
    c = Class.new {
      include Doki
      field :name do
        string 3
      end
    }
    record = c.new
    should.raise(Doki::Invalid) {
      record.new_data :name=>'1234'
      record.create
    }.message.should.match /must be shorter or equal to 3/
  end

end # === describe doki ===
