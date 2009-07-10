
# LRU based Hash

require 'enumerator'

# Hash with LRU expiry policy.  There are at most max_size elements in a
# LruHash.  When adding more elements old elements are removed according
# to LRU policy.
class LRUHash
  include Enumerable

  attr_reader :max_size
  attr_accessor :default, :default_proc, :release_proc

  def initialize(max_size, default_value = nil, &block)
    raise ArgumentError, 'Invalid max_size: %p' % max_size unless max_size > 0

    @max_size = max_size.to_i
    @default = default_value
    @default_proc = block

    @h = {}
    @head = Node.new
    @tail = front(Node.new)
  end

  def each_pair
    if block_given?
      n = @head.succ

      until n.equal? @tail
        yield n.key, n.value
        n = n.succ
      end

      self
    else
      enum_for :each_pair
    end
  end

  alias each each_pair

  def each_key(&b)
    if b
      @h.each_key(&b)
      self
    else
      enum_for :each_key
    end
  end

  def each_value
    if block_given?
      each_pair {|k, v| yield v}
      self
    else
      enum_for :each_value
    end
  end

  def size
    @h.size
  end

  def empty?
    @head.succ.equal? @tail
  end

  def fetch(key, &b)
    n = @h[key]

    if n
      front(n).value
    else
      (b || FETCH)[key]
    end
  end

  def [](key)
    fetch(key) do |k|
      @default_proc ? @default_proc[self, k] : default
    end
  end

  def keys
    @h.keys
  end

  def values
    @h.map {|k,n| n.value}
  end

  def has_key?(key)
    @h.has_key? key
  end

  alias key? has_key?
  alias member? has_key?
  alias include? has_key?

  def has_value?(value)
    each do |k, v|
      return true if value.eql? v
    end

    false
  end

  alias value? has_value?

  def values_at(*key_list)
    key_list.map {|k| self[k]}
  end

  def assoc(key)
    n = @h[key]

    if n
      front(n)
      [n.key, n.value]
    end
  end

  def rassoc(value)
    @h.each do |k, n|
      if value.eql? n.value
        front(n)
        return [n.key, n.value]
      end
    end
    nil
  end

  def store(key, value)
    # same optimization as in Hash
    key = key.dup.freeze if String === key && !key.frozen?

    n = @h[key]

    unless n
      if size == max_size
        # reuse node to optimize memory usage
        n = delete_oldest
        n.key = key
        n.value = value
      else
        n = Node.new key, value
      end

      @h[key] = n
    end

    front(n).value = value
  end

  alias []= store

  def delete(key)
    n = @h[key] and remove_node(n).value
  end

  def delete_if
    n = @head.succ

    until n.equal? @tail
      succ = n.succ
      remove_node n if yield n.key, n.value
      n = succ
    end

    self
  end

  def max_size=(limit)
    limit = limit.to_i

    while size > limit
      delete_oldest
    end

    @max_size = limit
  end

  def clear
    until empty?
      delete_oldest
    end

    self
  end

  def to_s
    s = nil
    each_pair {|k, v| (s ? (s << ', ') : s = '{') << k.to_s << '=>' << v.to_s}
    s ? (s << '}') : '{}'
  end

  alias inspect to_s

  FETCH = Proc.new {|k| raise KeyError, 'key not found'}

  # A single node in the doubly linked LRU list of nodes
  Node = Struct.new :key, :value, :pred, :succ do
    def unlink
      pred.succ = succ if pred
      succ.pred = pred if succ
      self.succ = self.pred = nil
      self
    end

    def insert_after(node)
      raise 'Cannot insert after self' if equal? node
      return self if node.succ.equal? self

      unlink

      self.succ = node.succ
      self.pred = node

      node.succ.pred = self if node.succ
      node.succ = self

      self
    end
  end

  private
  # move node to front
  def front(node)
    node.insert_after(@head)
  end

  # remove the node and invoke the cleanup proc
  # if set
  def remove_node(node)
    n = @h.delete(node.key)
    n.unlink
    release_proc and release_proc[n.key, n.value]
    n
  end

  # remove the oldest node returning the node
  def delete_oldest
    n = @tail.pred
    raise "Cannot delete from empty hash" if @head.equal? n
    remove_node n
  end
end
