
describe :href do

  before {
    CACHE[:datoki_db_href] ||= begin
                                reset_db <<-EOF
                                  CREATE TABLE "datoki_test" (
                                    id       serial       NOT NULL PRIMARY KEY,
                                    homepage varchar(255) NOT NULL
                                  );
                                EOF
                              end

    @klass = Class.new {
      include Datoki
      table :datoki_test
      field(:id) { primary_key }
      field(:homepage) { href }
    }
  }

  it "sets :type to :varchar" do
    @klass.fields[:homepage][:type].should == :varchar
  end

  it "sets :max to 255" do
    @klass.fields[:homepage][:max].should == 255
  end

  it "sets :min to 1" do
    @klass.fields[:homepage][:min].should == 1
  end

  it "sets :html_escape to :href" do
    @klass.fields[:homepage][:html_escape].should == :href
  end

  it "accepts a :min and :max" do
    CACHE[:datoki_db_href] = nil
    reset_db <<-EOF
      CREATE TABLE "datoki_test" (
        id       serial       NOT NULL PRIMARY KEY,
        homepage varchar(123) NOT NULL
      );
    EOF
    k = Class.new {
      include Datoki
      table :datoki_test
      field(:id) { primary_key }
      field(:homepage) { href 5, 123 }
    }
    k.fields[:homepage][:min].should == 5
    k.fields[:homepage][:max].should == 123
  end

  it "sets :min = 1 when null is allowed." do
    CACHE[:datoki_db_href] = nil
    reset_db <<-EOF
      CREATE TABLE "datoki_test" (
        id       serial       NOT NULL PRIMARY KEY,
        homepage varchar(222)
      );
    EOF
    k = Class.new {
      include Datoki
      table :datoki_test
      field(:id) { primary_key }
      field(:homepage) { href nil }
    }
    k.fields[:homepage][:min].should == 1
    k.fields[:homepage][:max].should == 222
  end

end # === describe :href

