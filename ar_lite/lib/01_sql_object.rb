require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    
    data = get_all_data
    
    @columns = data.first.map { |key| key.to_sym }
  end
  
  def self.get_all_data
    DBConnection.execute2(<<-SQL)
      SELECT 
        *
      FROM 
        #{self.table_name}
    SQL
  end

  def self.finalize!
    columns.each do |col|
      new_name = "@#{col.to_s}"
      
      define_method(col) do
        attributes
        @attributes[col]
      end
    
      define_method("#{col}=") do |arg|
        attributes
        @attributes[col] = arg
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    name = self.to_s
    
    @table_name ||= name.tableize
  end

  def self.all
    data = get_all_data
    parse_all(data.drop(1))
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    data = DBConnection.execute2(<<-SQL, id)
      SELECT 
        *
      FROM 
        #{self.table_name}
      WHERE
        id = ?
    SQL
    
    return nil if data.length == 1
    self.new(data.last) 
  end

  def initialize(params = {})
    params.each do |k, v|
      if self.class.columns.include?(k.to_sym)
        self.send("#{k}=", v)
      else
        raise "unknown attribute '#{k}'"
      end
    end
      
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end
  
  def attribute_values_with_id
    attribute_values.drop(1) + attribute_values.take(1)
  end
  
  def columns_except_id
    self.class.columns.drop(1)
  end

  def insert
    col_names = '(' + columns_except_id.join(", ") + ')'
    question_marks = "(" + (['?'] * columns_except_id.length).join(", ") + ")"
    
    DBConnection.execute2(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} #{col_names}
      VALUES 
        #{question_marks}
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_col_names = columns_except_id.join(" = ?,") + " = ?"
    
    DBConnection.execute2(<<-SQL, *attribute_values_with_id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    id ? update : insert
  end
end
