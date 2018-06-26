class Factory
  include Enumerable

  def self.new(*attributes, keyword_init: false, &block)
    first_attribute = attributes[0]
    flag = first_attribute.is_a?(String) && first_attribute.match(/[A-Z]/)
    class_name = flag ? attributes.shift : 'not given'
    attributes_size = attributes.size
    sorted_attributes = attributes.sort
    subclass = Class.new self do
    send(:attr_accessor, *attributes)

    class << self
      define_method :new do |*args|
        object = allocate
        object.send(:initialize, *args)
        object
      end
    end
    define_method :initialize do |*values|
      values_size = values.size
      given_values = values[0]
      if !keyword_init
        raise ArgumentError, 'Too many arguments' if values_size > attributes_size
        raise ArgumentError, 'Wrong number of arguments' if values_size < attributes_size
        values.each_with_index { |val, i| send("#{attributes[i]}=", val) }
      elsif given_values.keys.sort != sorted_attributes
        sorted_given_keys = given_values.keys.sort
        redundant_args = sorted_given_keys - sorted_attributes
        missing_args = sorted_attributes - sorted_given_keys
        raise ArgumentError, "Do not match expected keys: #{missing_args}, #{redundant_args}"
      else
        given_values.map { |k, v| instance_variable_set "@#{k}", v }
      end
    end

    define_method :[] do |member|
      if member.is_a?(String) || member.is_a?(Symbol)
        raise NameError unless members.include? member.to_sym
        return instance_variable_get("@#{member}")
      end
      if member.is_a? Integer
        raise IndexError if member > attributes_size || member < 0
        return to_a[member]
      end
      to_a[member.round(half: :down)] if member.is_a?(Float)
      end

      define_method :[]= do |member, value|
        if member.is_a?(String) || member.is_a?(Symbol)
          raise NameError unless members.include? member.to_sym
          return instance_variable_set("@#{member}", value)
        end
        if member.is_a? Integer
          raise IndexError if member > attributes_size || member < 0
          return instance_variable_set("@#{attributes[member]}", value)
        end
      end

      define_method :members do
        members = []
        instance_variables.each do |var|
          members << var.to_s.tr('@', '').to_sym
        end
        members
      end

      define_method :values_at do |*indices|
        indices.each do |index|
          raise IndexError if index > attributes_size || index < 0
        end
        to_a.values_at(*indices)
      end
    end
    class_eval(&block) if block_given?
    class_name == 'not given' ? subclass : const_set(class_name, subclass)
  end

  def ==(other)
    self.class == other.class && values == other.values
  end
  alias eql? ==

  def to_a
    variables = []
    instance_variables.each do |var|
      variables << instance_variable_get(var)
    end
    variables
  end
  alias values to_a

  def to_h
    variables = {}
    instance_variables.each do |var|
      var_name_for_hash = var.to_s.tr('@', '').to_sym
      variables[var_name_for_hash] = instance_variable_get(var)
    end
    variables
  end

  def length
    members.length
  end
  alias size length

  def dig(*keys)
    to_h.dig(*keys)
  end

  def each
    values.each { |v| yield(v) }
  end

  def select
    values.select { |v| yield(v) }
  end

  def each_pair
    to_h.each_pair { |key, val| yield(key, val) }
  end

  def inspect
    obj_to_str = to_h.map { |key, val| "#{key}='#{val}'" }.join(', ')
    "<factory #{self.class.name} #{obj_to_str}>"
  end
end
