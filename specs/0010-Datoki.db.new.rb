
describe 'Datoki.db :new' do

  before {
    CACHE[:datoki_db_new] ||= begin
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

  it "raises Schema_Conflict if field has not been defined, but exists in the db schema" do
    should.raise(Datoki::Schema_Conflict) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:id) { primary_key }
        field(:parent_id) { smallint }
        field(:body) { text nil, 1, 222 }
      }.new
    }.message.should.match /:title has not been defined/
  end

end # === describe Datoki.db :new


