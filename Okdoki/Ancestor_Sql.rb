
# ---------------------------------------------------------
#
#
# === Final result:
#
# WITH top_cte         AS ( ___ ),
#      mid_cte         AS ( ___ ),
#      another_mid_cte AS ( ___ ),
#      bottom_cte      AS ( ___ ),
#      last_cte        AS ( ___ )
#
#
# === top_cte
#
# SELECT ? AS class_id, id, NULL AS parent_id
# FROM :klass
# WHERE id IN ( SELECT parent_id FROM :middle_cte )
#
#
# === middle_cte
#
# SELECT ? AS class_id, id, ? AS parent_id
# FROM :klass
# WHERE id IN ( SELECT parent_id FROM :bottom_cte )
#
#
# === bottom_cte
#
# SELECT ? AS class_id, ? AS id, ? AS parent_id
#
#
# === last_cte
#
# SELECT class_id, id from top_parent
# UNION
# SELECT class_id, id from mid_parent
# UNION
# SELECT class_id, id from other_mid_parent
# UNION
# SELECT class_id, id from bottom_parent
#
#
# ---------------------------------------------------------

require 'i_dig_sql'
require_crud :Customer, :Screen_Name
class Story
  include Okdoki::Model
  class << self
    def okdoki_id
      10
    end
  end # === class self ===
end

class Magazine
  include Okdoki::Model
  class << self
    def okdoki_id
      11
    end
  end # === class self ===
end

module Okdoki

  class Ancestor_Sql

    COLS = {
      Story       => { :fkey => :mag_id       , :parent_klass => Magazine    }.freeze,
      Magazine    => { :fkey => :publisher_id , :parent_klass => Screen_Name }.freeze,
      Screen_Name => { :fkey => :owner_id     , :parent_klass => Customer    }.freeze,
      Customer    => { :fkey => nil           , :parent_klass => nil         }.freeze
    }

    def initialize rec
      @rec  = rec
      @tree = []
      klass = @rec.class
      begin
        meta         = self.class::COLS[klass].dup
        meta[:klass] = klass
        @tree.unshift meta
        klass = meta[:parent_klass]
      end while klass
    end

    def to_sql

      top = @tree.first
      bottom  = @tree.last

      tree = @tree.reverse.inject([]) do |memo, curr|
        prev = memo.last

        memo << begin
                  case curr
                  when top
                    q = I_Dig_Sql.new
                    q.SELECT("? AS class_id, id, NULL AS parent_id")
                    .FROM(curr[:klass].table_name)
                    .WHERE("id IN (#{prev.to_sql[:sql]})")
                    # .WHERE("id", :IN, prev)
                  when bottom
                    q = I_Dig_Sql.new
                    q.SELECT("? AS class_id, id, ? AS parent_id")
                    .FROM(curr[:klass].table_name)
                    .WHERE("id = '#{@rec.id}'")
                    # .WHERE("id", :'=', @rec.id)
                  else # it's a middle
                    q = I_Dig_Sql.new
                    q.SELECT("? AS class_id, id, ? AS parent_id")
                    .FROM(curr[:klass].table_name)
                    .WHERE("id IN (#{prev.to_sql[:sql]})")
                    # .WHERE("id", :IN, prev)
                  end
        end

        memo
      end # == inject

      return tree

      size       = @with.size
      last_index = size - 1

      @with.each_with_index { |meta, i|
        klass        = meta[:klass]
        table_name   = klass.table_name.to_s
        child_klass  = @with[i + 1] && @with[i + 1][:klass]
        fkey_name    = meta[:fkey]
        parent_klass = meta[:parent_klass]
        id           = meta[:id]

        args.push klass.okdoki_id

        template     = if i == 0
                         SQL_Templates[0]
                       elsif i != last_index
                         args.push meta[:fkey].to_s
                         SQL_Templates[1]
                       else
                         args.push meta[:fkey].to_s
                         SQL_Templates[2]
                       end

        sql << %^
          :klass_parent AS (
            #{template}
          )
        ^.gsub(':klass', table_name)

        selects << %^
          SELECT class_id, id
          FROM :klass_parent
        ^.gsub(':klass', table_name)

        sql.last.gsub!(':child_klass', child_klass.table_name.to_s) if child_klass
      }

    end

  end # === class Ancestor_Sql ===

end # === module Okdoki ===








