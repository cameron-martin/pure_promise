describe PurePromise::Callback do

  let(:return_promise) { PurePromise.new }

  describe '#call' do

    it 'delegates to calling proc' do
      promise = PurePromise.fulfill(:value)
      callback = double('callback')

      expect(callback).to receive(:call).with(:value).and_return(promise)

      PurePromise::Callback.new(callback, return_promise).call(:value)
    end

    it 'rejects promise if callback errors' do
      error = RuntimeError.new
      callback = proc { raise error }

      PurePromise::Callback.new(callback, return_promise).call(:value)

      expect_rejection(return_promise, with: error)
    end
  end

end