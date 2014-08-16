class PurePromise
  class Callback

    def initialize(callback, return_promise)
      @callback = callback
      @return_promise = return_promise
    end

    # TODO: Return a consistent value here. Nil? self?
    def call(value)
      return_value = @callback.call(value)
    rescue Exception => error
      @return_promise.reject(error)
    else
      @return_promise.resolve(return_value)
    end

  end
end