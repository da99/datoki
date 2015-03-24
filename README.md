
# Datoki

A Ruby gem for managing validation and records using PostgreSQL.

## Installation

    gem 'datoki'

## Usage

```ruby
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

