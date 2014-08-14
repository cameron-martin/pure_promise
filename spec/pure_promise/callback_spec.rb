describe PurePromise::Callback do

  let(:return_promise) { PurePromise.new }

  describe '#call' do

    it 'delegates to calling proc' do
      promise = PurePromise.fulfill(:value)
      callback = double('callback')

      expect(callback).to receive(:call).with(:value).and_return(promise)

      return_value = PurePromise::Callback.new(callback, return_promise).call(:value)

      expect(return_value).to equal(promise)
    end

    # TODO: consider removing this, as this check is not handled directly by Callback
    it 'raises error if it does not return a promise' do
      expect { PurePromise::Callback.new(proc { }, return_promise).call(:value) }.to raise_error(TypeError)
    end
  end

end