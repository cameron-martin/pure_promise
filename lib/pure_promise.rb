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

    run_callbacks(@callbacks.map(&:first))
    @callbacks.clear

    self
  end

  def reject(value=nil)
    raise MutationError, 'You can only reject a pending promise' unless pending?

    @state = :rejected
    @value = value

    run_callbacks(@callbacks.map(&:last))
    @callbacks.clear

    self
  end

  def resolve(promise)
    if equal?(promise)
      raise TypeError, 'Promise cannot be resolved to itself'
    elsif promise.instance_of?(self.class)
      resolve_pure_promise(promise)
    #elsif is_thenable?(promise)
    #  resolve_pure_promise(coerce_thenable(promise))
    else
      raise TypeError, 'Argument is not a promise'
    end
  end

private

  def defer
    yield
    nil # We can't rely on defer evaluating to what the block evalutes to
  end

  # This ensures that all callbacks run in order, by setting up an execution chain like
  # proc { defer { a.call; proc { defer { b.call; ... } }.call  } }.call
  # You might think this is really slow by only running one callback per tick,
  # but here are some benchmarks with eventmachine: https://gist.github.com/cameron-martin/08abeaeae1bf746ef718
  #
  # We do this because we do not want to require implementations of defer to execute blocks in the order they were registered.
  def run_callbacks(callbacks)
    callbacks.reverse.inject(proc{}) do |memo, callback|
      proc { defer { callback.call(@value); memo.call } }
    end.call
  end

  #def coerce_thenable(thenable)
  #  self.class.new(&thenable.method(:then))
  #end
  #
  #def is_thenable?(thenable)
  #  thenable.respond_to?(:then) && thenable.method(:then).arity == 2
  #end

  # TODO: Implement 'Ruby equality trick' to hide #value
  def resolve_pure_promise(promise)
    if promise.fulfilled?
      fulfill(promise.value)
    elsif promise.rejected?
      reject(promise.value)
    else
      promise.then(method(:fulfill), method(:reject))
    end
  end

end
