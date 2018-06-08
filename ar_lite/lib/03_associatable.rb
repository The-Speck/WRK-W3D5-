require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )
  

  def model_class
    # Object.const_get(class_name)
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default = {
      foreign_key: "#{name}_id".to_sym,
      class_name: "#{name.to_s.camelcase}",
      primary_key: :id
    }
    
    default.merge!(options)
    
    @foreign_key = default[:foreign_key]
    @class_name = default[:class_name]
    @primary_key = default[:primary_key]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    # byebug
    default = {
      foreign_key: "#{self_class_name.to_s.downcase}_id".to_sym,
      class_name: "#{name.to_s.singularize.camelcase}",
      primary_key: :id
    }
    
    default.merge!(options)
    
    @foreign_key = default[:foreign_key]
    @class_name = default[:class_name]
    @primary_key = default[:primary_key]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    
    define_method(name) do 
      f_k = self.send("#{options.foreign_key}")
      options.model_class.find(f_k)
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    
    define_method(name) do 
      p_k = self.send("#{options.primary_key}")
      data = DBConnection.execute2(<<-SQL, id)
        SELECT 
          *
        FROM 
          #{options.table_name}
        WHERE
          #{options.foreign_key} = ?
      SQL
      
      data.drop(1).map { |datum| options.model_class.new(datum) }
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
