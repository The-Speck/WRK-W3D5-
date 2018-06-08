require 'byebug'
class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      new_name = "@#{name.to_s}"
      
      define_method(name) do
        instance_variable_get(new_name)
      end
      
      define_method("#{name}=") do |arg|
        instance_variable_set(new_name, arg)
      end
    end
  end
end