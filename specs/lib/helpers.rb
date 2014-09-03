
require 'Bacon_Colored'
require 'datoki'
require 'pry'
require 'sequel'

DB = Sequel.connect ENV['DATABASE_URL']
DB.cache_schema = false

Datoki.db DB

def reset_db sql = nil
  DB << "DROP TABLE IF EXISTS \"datoki_test\";"
  sql ||= <<-EOF
      CREATE TABLE "datoki_test" (
        id serial NOT NULL PRIMARY KEY,
        title varchar(123) NOT NULL,
        body  text
      );
  EOF
  DB << sql
end # === def reset_db

reset_db
