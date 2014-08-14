module HelperMacros

  # TODO: Dry this up

  def expect_fulfillment(promise, options={})
    fulfill_callback, reject_callback = create_callback_doubles

    promise.then(fulfill_callback, reject_callback)

    yield if block_given?

    expect(fulfill_callback).to have_received(:call).with(options[:with] || anything)
    expect(reject_callback).to_not have_received(:call)
  end

  def expect_rejection(promise, options={})
    fulfill_callback, reject_callback = create_callback_doubles

    promise.then(fulfill_callback, reject_callback)

    yield if block_given?

    expect(reject_callback).to have_received(:call).with(options[:with] || anything)
    expect(fulfill_callback).to_not have_received(:call)
  end

private

  def create_callback_doubles
    [
      double('fulfill_callback', call: PurePromise.fulfill),
      double('reject_callback', call: PurePromise.reject)
    ]
  end
end