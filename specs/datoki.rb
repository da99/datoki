
describe Datoki do

  it "runs" do
    c = Class.new {
      include Datoki
      field :name do
        string 3
      end
    }
    record = c.new
    should.raise(Datoki::Invalid) {
      record.create :name=>'1234'
    }.message.should.match /must be shorter or equal to 3/
  end

end # === describe Datoki ===
