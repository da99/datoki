
describe "Datoki.db Schema_Conflict" do

  before {
    CACHE[:schema_conflict] ||= begin
                                  reset_db <<-EOF
                                    CREATE TABLE "datoki_test" (
                                      id     serial NOT NULL PRIMARY KEY,
                                      title  varchar(123),
                                      body   varchar(255) NOT NULL,
                                      created_at  timestamp with time zone NOT NULL DEFAULT timezone('UTC'::text, now())
                                    );
                                  EOF
                                end
  }

  it "raises Schema_Conflict when specified to allow nil, but db doesn not" do
    should.raise(Datoki::Schema_Conflict) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:body) { varchar nil, 1, 255 }
      }
    }.message.should.match /:allow_null: false != true/i
  end

  it "raises Schema_Conflict when there is a :max_length conflict" do
    should.raise(Datoki::Schema_Conflict) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:title) { varchar nil, 1, 200 }
      }
    }.message.should.match /:max: 123 != 200/i
  end

end # === describe Datoki.db

