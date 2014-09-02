
require 'Bacon_Colored'
require 'datoki'
require 'pry'
require 'sequel'

DB = Sequel.connect ENV['DATABASE_URL']
Datoki.db DB

def reset_db
  DB << "DROP TABLE IF EXISTS \"datoki_test\";"
  DB << <<-EOF
    CREATE TABLE "datoki_test" (
      id serial NOT NULL PRIMARY KEY,
      title varchar(123),
      body  text
    );
  EOF
end # === def reset_db

