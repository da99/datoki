
# Datoki

A Ruby gem that is part abstraction layer, part validator...
for managing data in PostgreSQL.

## Installation

    gem 'datoki'

## Usage

```ruby
  # === Set it up: =======================
  require 'datoki'
  require 'sequel'
  DB = Sequel.connect ENV['DATABASE_URL']
  DB.cache_schema = false
  Datoki.db DB
  # ======================================

  class Computer
    include Datoki

    field(:id)   { primary_key }
    field(:name) { varchar }
    field(:desc) { text nil, 1, 955 }

    on :create_or_update? do

      on :create? do
        clean :name, :desc
      end

      on :update? do

        clean :name, :desc

        on :special? do
          skip :db
          # do special processing
        end
      end

    end # === :create_or_update?


  end # === class
```

## NOTE:

1) Raises an error if a mismatch between field definition and schema.
Example: `:allow_null != field[:allow][:null]`
