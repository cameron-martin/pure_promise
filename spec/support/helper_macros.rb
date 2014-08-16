module HelperMacros
  def expect_fulfillment(promise, options={})
    setup_state_expectation(promise) do |fulfill_callback, reject_callback|
      yield if block_given?

      expect(fulfill_callback).to have_received(:call).with(options[:with] || anything)
      expect(reject_callback).to_not have_received(:call)
    end
  end

  def expect_rejection(promise, options={})
    setup_state_expectation(promise) do |fulfill_callback, reject_callback|
      yield if block_given?

      expect(reject_callback).to have_received(:call).with(options[:with] || anything)
      expect(fulfill_callback).to_not have_received(:call)
    end
  end

  def expect_pending(promise)
    setup_state_expectation(promise) do |fulfill_callback, reject_callback|
      expect(fulfill_callback).to_not have_received(:call)
      expect(reject_callback).to_not have_received(:call)
    end
  end

private

  def setup_state_expectation(promise)
    fulfill_callback = double('fulfill_callback', call: PurePromise.fulfill)
    reject_callback = double('reject_callback', call: PurePromise.reject)

    promise.then(fulfill_callback, reject_callback)

    yield fulfill_callback, reject_callback
  end
end