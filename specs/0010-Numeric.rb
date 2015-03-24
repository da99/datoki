
describe Numeric do

  before {
    CACHE[:numeric_class] ||= begin
                                Class.new {
                                  include Datoki
                                  field(:id)  { primary_key }
                                  field(:age) { smallint 1, 150 }
                                  def create
                                    clean :age
                                  end
                                }
                              end
  }


  it "fails if number is outside the range" do
    r = catch(:invalid) {
      CACHE[:numeric_class].create :age=>0
    }
    r.error[:msg].should.match /age must be between 1 and 150/i
  end

  it "throws :invalid if value is a non-numeric varchar." do
    r = catch(:invalid) {
      CACHE[:numeric_class].create :age=>'twenty-two'
    }
    r.error[:msg].should.match /age must be numeric/i
  end

  it "allows nil" do
    Class.new {
      include Datoki
      field(:id) { primary_key }
      field(:age) { smallint nil, 1, 99 }
      def create
        clean :age
      end
    }.create(:age=>nil).
    clean.should == {:age=>nil}
  end

  it "allows nil in an array" do
    Class.new {
      include Datoki
      field(:id) { primary_key }
      field(:age) { smallint [nil, 1,2,3,4] }
      def create
        clean :age
      end
    }.create(:age=>nil).
    clean.should == {:age=>nil}
  end

  it "allows to specify an Array of possible values" do
    Class.new {
      include Datoki
      field(:id) { primary_key }
      field(:age) { smallint [1,2,3,4] }
      def create
        clean :age
      end
    }.create(:age=>2).
    clean[:age].should == 2
  end

  it "fails if value is not in Array of possible values" do
    catch(:invalid) {
      Class.new {
        include Datoki
        field(:id) { primary_key }
        field(:num) { smallint [1,2,3,4] }
        def create
          clean :num
        end
      }.create :num=>0
    }.error[:msg].should.match /Num can only be: 1, 2, 3, 4/
  end

end # === describe Numeric
