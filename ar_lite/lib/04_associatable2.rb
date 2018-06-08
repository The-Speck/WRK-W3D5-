require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  # def has_one_through(name, through_name, source_name)
  #   define_method(name) do
  #     obj = self.send(through_name)
  #     obj.send(source_name)
  #   end
  # end
  
  def has_one_through(name, through_name, source_name)
    through = assoc_options[through_name]
    source = through
      .model_class
      .assoc_options[source_name]
      
    #through -> called from cat
      #foreign_key :owner_id
      #class_name 'Human'
      #primary_key :id
    #source -> called from human
      #foreign_key :house_id
      #class_name 'House'
      #primary_key :id
    
    define_method(name) do
    
      data = DBConnection.execute2(<<-SQL, self.send(through.foreign_key))
      SELECT
        #{source.table_name}.*
      FROM
        #{through.table_name} JOIN #{source.table_name} 
          ON #{through.table_name}.#{source.foreign_key} = #{source.table_name}.id
      WHERE
        #{through.table_name}.id = ?
      SQL
    
      source.model_class.new(data.last)
    end
  end
end
