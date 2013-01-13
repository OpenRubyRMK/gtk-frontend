# A recursive hash-like container class. It basically behaves like
# a minimal version of Hash, but allows to listen for a :value_set
# event that is emitted each time something is stored inside it.
#
# Example:
#
#   s = EventedStorage.new
#   s[:foo][:bar] = "Hi there"
#   p s[:foo][:bar] #=> "Hi there"
#   s.observe(:value_set){|sender, event, info| p(info)}
#   s[:foo] = 3 #=> {:key => :foo, :value => 3}
#   s[:blubb] = 9 #=> {:key => :blubb, :value => 9}
class OpenRubyRMK::GTKFrontend::EventedStorage
  include OpenRubyRMK::Backend::Eventable
  include Enumerable

  # Creates a new EventedStorage.
  def initialize
    @storage_proc = lambda{self.class.new}
    @storage = {}
  end

  # Grabs the value stored for +key+. If there is no value
  # for +key+, returns a new EventedStorage instance instead.
  # In the latter case, the +value_set+ event is emitted with
  # +key+ as the :key parameter and the new EventedStorage
  # instance as the :value parameter.
  def [](key)
    if @storage.has_key?(key)
      @storage[key]
    else
      changed

      val       = @storage_proc.call
      self[key] = val

      notify_observers(:value_set, :key => key, :value => val)
      val
    end
  end

  # Sets the +value+ stored for +key+. Emits the +value_set+
  # event with the proper parameters.
  def []=(key, value)
    changed

    @storage[key] = value
    notify_observers(:value_set, :key => key, :value => value)
    value
  end

  # Human-readable description.
  def inspect
    "#<#{self.class} #{@storage.inspect}>"
  end

  # Yields each key-value pair in this store to the block.
  def each_pair(&block)
    @storage.each_pair(&block)
  end
  alias each each_pair

end
