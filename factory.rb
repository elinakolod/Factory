class Factory
  def self.new(*attributes, keyword_init: false, &block)
    flag = attributes[0].is_a?(String) && attributes[0].match(/[A-Z]/)
    class_name = flag ? attributes.shift : nil
    subclass = Class.new self do
      class_eval(&block) if block_given?
      send(:attr_accessor, *attributes)

      class << self
        define_method :new do |*args|
          object = allocate
          object.send(:initialize, *args)
          object
        end
      end
      define_method :initialize do |*values|
        if !keyword_init
          raise ArgumentError, 'Too many arguments' if values.size > attributes.size
          raise ArgumentError, 'Wrong number of arguments' if values.size < attributes.size
          values.each_with_index { |val, i| send("#{attributes[i]}=", val) }
        elsif values[0].keys.sort != attributes.sort
          redundant_args = values[0].keys.sort - attributes.sort
          missing_args = attributes.sort - values[0].keys.sort
          raise ArgumentError, "Do not match expected keys: #{missing_args}, #{redundant_args}"
        else
          values[0].map { |k, v| instance_variable_set "@#{k}", v }
        end
      end

      define_method :[] do |member|
        if member.is_a?(String) || member.is_a?(Symbol)
          return instance_variable_get("@#{member}")
        end
        if member.is_a? Integer
          raise IndexError if member > attributes.size
          return to_a[member]
        end
      end

      define_method :[]= do |member, value|
        instance_variable_set("@#{member}", value)
      end

      define_method :members do
        members = []
        instance_variables.each do |var|
          members << var.to_s.tr('@', '').to_sym
        end
        members
      end
    end
    class_name.nil? ? subclass : Object.const_set(class_name, subclass)
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

  def values_at(*indices)
    to_a.values_at(*indices)
  end

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
