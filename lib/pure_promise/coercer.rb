# This coerces a thenable into a PurePromise
# I wanted to keep this separate because there are a lot of edge cases that need handling
# if the thenable doesn't conform to the spec properly.

class PurePromise
  class Coercer

    def self.is_thenable?(thenable)
      thenable.respond_to?(:then)
    end

    def self.coerce(*args, &block)
      new(*args, &block).coerce
    end

    def initialize(thenable, promise_class)
      raise TypeError, 'Can only coerce a thenable' unless self.class.is_thenable?(thenable)
      @thenable = thenable
      @promise_class = promise_class
    end

    def coerce
      return @thenable if @thenable.instance_of?(@promise_class)

      @mutated = false
      coerce_thenable
    end

  private

    def coerce_thenable
      @promise_class.new.tap do |promise|
        begin
          @thenable.then(
              build_callback(promise, :fulfill),
              build_callback(promise, :reject)
          )
        rescue Exception => error
          mutate_promise { promise.reject(error) }
        end
      end
    end

    def build_callback(promise, method)
      proc do |value|
        mutate_promise { promise.public_send(method, value) }
        promise
      end
    end

    def mutate_promise
      unless @mutated
        yield
        @mutated = true
      end
    end

  end
end