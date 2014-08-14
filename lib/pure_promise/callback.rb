class PurePromise
  class Callback

    def initialize(callback, return_promise)
      @callback = callback
      @return_promise = return_promise
    end

    def call(value)
      @callback.call(value).tap do |return_value|
        @return_promise.resolve_to(return_value)
      end
    end

  end
end