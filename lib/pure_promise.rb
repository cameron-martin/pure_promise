require 'pure_promise/callback'

class PurePromise

  attr_reader :value

  MutationError = Class.new(RuntimeError)

  def self.fulfill(*args, &block)
    new.fulfill(*args, &block)
  end

  def self.reject(*args, &block)
    new.reject(*args, &block)
  end

  def initialize
    @state = :pending # Pending/fulfilled/rejected
    @value = nil

    @callbacks = []

    yield method(:fulfill), method(:reject) if block_given?
  end

  # REVIEW: Are these defaults correct?
  def then(fulfill_callback=proc { self }, reject_callback=proc { self })
    PurePromise.new.tap do |return_promise|

      fulfill_callback = Callback.new(fulfill_callback, return_promise)
      reject_callback = Callback.new(reject_callback, return_promise)

      if fulfilled?
        defer { fulfill_callback.call(@value) }
      elsif rejected?
        defer { reject_callback.call(@value) }
      else
        @callbacks << [fulfill_callback, reject_callback]
      end

    end
  end

  #def catch(callback)
  #  self.then(proc { self }, callback)
  #end

  # TODO: consider removing these
  def pending?
    @state.equal?(:pending)
  end

  def fulfilled?
    @state.equal?(:fulfilled)
  end

  def rejected?
    @state.equal?(:rejected)
  end

  def fulfill(value=nil)
    raise MutationError, 'You can only fulfill a pending promise' unless pending?

    @state = :fulfilled
    @value = value

    # TODO: Call these deferred, but in the correct order.
    # Can we rely on implementations of defer, or do we have to do a fold over defer { a; b }?
    @callbacks.map(&:first).each { |callback| callback.call(value) }
    self
  end

  def reject(value=nil)
    raise MutationError, 'You can only reject a pending promise' unless pending?

    @state = :rejected
    @value = value
    @callbacks.map(&:last).each { |callback| callback.call(value) }
    self
  end

  def resolve_to(promise)
    raise TypeError, 'Promise cannot be resolved to itself' if equal?(promise)

    if promise.is_a?(PurePromise)
      resolve_to_pure_promise(promise)
    else
      raise TypeError, 'Argument is not a promise'
    end
  end

private

  def defer
    yield
    nil # We can't rely on defer evaluating to what the block evalutes to
  end

  # TODO: Implement 'Ruby equality trick' to hide #value
  def resolve_to_pure_promise(promise)
    if promise.fulfilled?
      fulfill(promise.value)
    elsif promise.rejected?
      reject(promise.value)
    else
      promise.then(method(:fulfill), method(:reject))
    end
  end

end
