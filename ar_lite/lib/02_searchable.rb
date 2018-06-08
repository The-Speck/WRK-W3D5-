require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    vals = params.values
    keys = params.keys
    where_clause = keys.join(" = ? AND ") + " = ?"
    
    data = DBConnection.execute2(<<-SQL, vals)
      SELECT 
        *
      FROM 
        #{self.table_name}
      WHERE
        #{where_clause}
    SQL
    
    data.drop(1).map { |d| self.new(d) }
  end
end

class SQLObject
  extend Searchable
end
