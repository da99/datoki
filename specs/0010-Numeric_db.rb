
describe 'Datoki.db number' do

  before {
    CACHE[:datoki_db_number] ||= begin
                                    reset_db <<-EOF
                                      CREATE TABLE "datoki_test" (
                                        id serial NOT NULL PRIMARY KEY,
                                        parent_id smallint NOT NULL,
                                        title varchar(123) NOT NULL,
                                        body  text
                                      );
                                    EOF
                                  end
  }

  it "does not set :min = 1" do
    Class.new {
      include Datoki
      table :datoki_test
      field(:parent_id) { smallint }
    }.
    fields[:parent_id][:min].should == nil
  end

end # === Datoki.db number


