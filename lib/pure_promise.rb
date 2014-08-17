require 'pure_promise/callback'
require 'pure_promise/coercer'

class PurePromise

  MutationError = Class.new(RuntimeError)

  class << self
    extend Forwardable

    def_delegators :new, :fulfill, :reject, :resolve

    # TODO: Clean this up, it's pretty messy.
    def error(message_or_exception=nil, message=nil, backtrace=nil)
      backtrace ||= caller(2) # Fix for jRuby - See https://github.com/jruby/jruby/issues/1908
      if message_or_exception.respond_to?(:exception)
        exception = message_or_exception.exception(message || message_or_exception)
      else
        exception = RuntimeError.new(message_or_exception)
      end
      exception.set_backtrace(backtrace)
      reject(exception)
    end
  end

  def initialize
    @state = :pending # Pending/fulfilled/rejected
    @callbacks = []

    yield method(:fulfill), method(:reject) if block_given?
  end

  # REVIEW: Consider having two callback chains, to avoid having potentially expensive null_callbacks littering @callbacks
  def then(fulfill_callback=null_callback, reject_callback=null_callback, &block)
    fulfill_callback = block if block
    self.class.new.tap do |return_promise|
      register_callbacks(
          Callback.new(fulfill_callback, return_promise),
          Callback.new(reject_callback, return_promise)
      )
    end
  end

  def catch(&block)
    self.then(null_callback, block || null_callback)
  end

  def fulfill(value=nil)
    mutate_state(:fulfilled, value, @callbacks.map(&:first))
  end

  def reject(value=nil)
    mutate_state(:rejected, value, @callbacks.map(&:last))
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
    raise TypeError, 'Argument must be of same type as self' unless pure_promise.instance_of?(self.class)

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
  end

  def mutate_state(state, value, callbacks)
    raise MutationError, 'You can only mutate pending promises' unless pending?

    @state = state
    @value = value

    run_callbacks(callbacks)
    # TODO: Find a way of testing this - It makes no visible changes, apart from clearing some memory.
    @callbacks.clear

    self
  end

  def register_callbacks(fulfill_callback, reject_callback)
    if fulfilled?
      defer { fulfill_callback.call(@value) }
    elsif rejected?
      defer { reject_callback.call(@value) }
    else
      @callbacks << [fulfill_callback, reject_callback]
    end
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

  [:pending, :fulfilled, :rejected].each do |state|
    define_method("#{state}?") do
      @state.equal?(state)
    end
  end

end
