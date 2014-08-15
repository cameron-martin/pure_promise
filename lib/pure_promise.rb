require 'pure_promise/callback'
require 'pure_promise/coercer'

class PurePromise

  MutationError = Class.new(RuntimeError)

  class << self
    extend Forwardable

    def_delegators :new, :fulfill, :reject
  end

  def initialize
    @state = :pending # Pending/fulfilled/rejected
    @callbacks = []

    yield method(:fulfill), method(:reject) if block_given?
  end

  # REVIEW: Consider having two callback chains, to avoid having potentially expensive null_callbacks littering @callbacks
  def then(fulfill_callback=null_callback, reject_callback=null_callback)
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
  #  self.then(null_callback, callback)
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
    # TODO: Find a way of testing this - It makes no visible changes, apart from clearing some memory.
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
    elsif Coercer.is_thenable?(promise)
      Coercer.coerce(promise, self.class).resolve_into(self)
      self
    else
      raise TypeError, 'Argument is not a promise'
    end
  end

  def resolve_into(pure_promise)
    if fulfilled?
      pure_promise.fulfill(@value)
    elsif rejected?
      pure_promise.reject(@value)
    else
      self.then(pure_promise.method(:fulfill), pure_promise.method(:reject))
    end
    self
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


  def null_callback
    @null_callback ||= proc { self }
  end

end
