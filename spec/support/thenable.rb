module Thenable
  class Conformant

    def fulfill(value)
      @fulfill_callback.call(value)
    end

    def reject(value)
      @reject_callback.call(value)
    end

    def then(fulfill_callback, reject_callback)
      @fulfill_callback = fulfill_callback
      @reject_callback = reject_callback
    end

  end

  class EarlyErroring

    def initialize(error)
      @error = error
    end

    def then(_, _)
      raise @error
    end

  end

  class LateErroring

    def initialize(value, error)
      @value = value
      @error = error
    end

    def then(fulfill_callback, _)
      fulfill_callback.call(@value)
      raise @error
    end

  end
end