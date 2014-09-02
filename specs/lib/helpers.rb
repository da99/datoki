
require 'Bacon_Colored'
require 'datoki'
require 'pry'
require 'sequel'

DB = Sequel.connect ENV['DATABASE_URL']
Datoki.db DB

def reset_db sql = nil
  DB << "DROP TABLE IF EXISTS \"datoki_test\";"
  sql ||= <<-EOF
      CREATE TABLE "datoki_test" (
        id serial NOT NULL PRIMARY KEY,
        parent_id smallint NOT NULL,
        title varchar(123) NOT NULL,
        body  text
      );
  EOF
  DB << sql
end # === def reset_db

reset_db
