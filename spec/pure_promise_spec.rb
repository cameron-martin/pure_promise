describe PurePromise do

  subject { PurePromise.new }

  let(:fulfill_callback) { double('fulfill_callback').as_null_object }
  let(:reject_callback) { double('reject_callback').as_null_object }

  describe '#initialize' do
    it 'yields fullfill and reject methods if block given' do
      expect do |b|
        PurePromise.new(&b)
      end.to yield_with_args(
                 a_bound_method_of(PurePromise.instance_method(:fulfill)),
                 a_bound_method_of(PurePromise.instance_method(:reject))
             )
    end

    it 'initializes as pending' do
      expect_pending(PurePromise.new)
    end
  end

  describe '.error' do

    it 'rejects to a RuntimeError with no arguments' do
      promise = PurePromise.error

      expect_rejection(promise, with: an_error(RuntimeError).with_backtrace(caller))
    end

    it 'rejects to a RuntimeError with message with single string argument' do
      promise = PurePromise.error('error message')

      expect_rejection(promise, with: an_error(RuntimeError, 'error message').with_backtrace(caller))
    end

    it 'rejects to a specific error when given an Exception object' do
      exception = TypeError.new('error message')
      promise = PurePromise.error(exception)

      expect_rejection(promise, with: an_error(TypeError, 'error message').with_backtrace(caller))
    end

    it 'rejects to a specific error when given a exception class and string' do
      promise = PurePromise.error(TypeError, 'error message')

      expect_rejection(promise, with: an_error(TypeError, 'error message').with_backtrace(caller))
    end

    it 'sets custom backtrace if given third argument' do
      backtrace = ['something']
      promise = PurePromise.error(TypeError, 'error message', backtrace)

      expect_rejection(promise, with: an_error(TypeError, 'error message').with_backtrace(backtrace))
    end

  end

  # TODO: Test delegation of .fulfill and .reject

  describe '#fulfill' do
    it 'calls fulfill callback when promise transitions to fulfilled' do
      expect_fulfillment(subject, with: :value) do
        subject.fulfill(:value)
      end
    end

    it 'is fulfilled' do
      subject.fulfill
      expect_fulfillment(subject)
    end

    it 'should raise error if fulfill twice' do
      subject.fulfill
      expect { subject.fulfill }.to raise_error(PurePromise::MutationError, 'You can only mutate pending promises')
    end

    it 'should raise error if fulfilled after being rejected' do
      subject.reject
      expect { subject.fulfill }.to raise_error(PurePromise::MutationError, 'You can only mutate pending promises')
    end

    it 'returns self' do
      expect(subject.fulfill).to eq(subject)
    end
  end

  describe '#reject' do
    it 'calls reject callback when promise transitions to rejected' do
      expect_rejection(subject, with: :value) do
        subject.reject(:value)
      end
    end

    it 'is rejected' do
      subject.reject
      expect_rejection(subject)
    end

    it 'should raise error if rejected twice' do
      subject.reject
      expect { subject.reject }.to raise_error(PurePromise::MutationError, 'You can only mutate pending promises')
    end

    it 'should raise error if rejected after being fulfilled' do
      subject.fulfill
      expect { subject.reject }.to raise_error(PurePromise::MutationError, 'You can only mutate pending promises')
    end

    it 'returns self' do
      expect(subject.reject).to eq(subject)
    end
  end

  describe '#resolve' do

    it 'raises TypeError if argument is same as self' do
      expect { subject.resolve(subject) }.to raise_error(TypeError, 'Promise cannot be resolved to itself')
    end

    it 'raises TypeError if argument is not a promise' do
      expect { subject.resolve(Object.new) }.to raise_error(TypeError, 'Argument is not a promise')
    end

    context 'when argument is a promise' do
      let(:argument) { PurePromise.new }

      it 'returns self when argument is pending' do
        return_value = subject.resolve(argument)

        expect(return_value).to eq(subject)
      end

      it 'fulfills subject if argument is fulfilled' do
        argument.fulfill(:value)
        subject.resolve(argument)

        expect_fulfillment(subject, with: :value)
      end

      it 'rejects subject if argument is rejected' do
        argument.reject(:value)
        subject.resolve(argument)

        expect_rejection(subject, with: :value)
      end

      it 'fulfills subject when argument is fulfilled' do
        subject.resolve(argument)
        argument.fulfill(:value)

        expect_fulfillment(subject, with: :value)
      end

      it 'rejects subject when argument is rejected' do
        subject.resolve(argument)
        argument.reject(:value)

        expect_rejection(subject, with: :value)
      end
    end

    context 'when argument is a thenable' do
      it 'fulfills when callback passed to then is called' do
        thenable = Thenable::Conformant.new

        subject.resolve(thenable)

        expect_fulfillment(subject, with: :value) do
          thenable.fulfill(:value)
        end
      end

      it 'rejects when callback passed to then is called' do
        thenable = Thenable::Conformant.new

        subject.resolve(thenable)

        expect_rejection(subject, with: :value) do
          thenable.reject(:value)
        end
      end
    end

  end

  describe '#then' do

    it 'is a promise' do
      return_promise = subject.then(fulfill_callback, reject_callback)
      expect(return_promise).to be_an_instance_of(subject.class)
    end

    it 'executes callbacks in order' do
      callbacks = 2.times.map do
        double('fulfill_callback').as_null_object
      end.each do |callback|
        subject.then(callback)
      end

      callbacks.each do |callback|
        expect(callback).to receive(:call).and_return(PurePromise.fulfill).ordered
      end

      subject.fulfill
    end

    # TODO: Find a better way of testing this
    it 'calls defer if fulfilled' do
      subject.fulfill
      expect(subject).to receive(:defer)
      subject.then
    end

    it 'calls defer if rejected' do
      subject.reject
      expect(subject).to receive(:defer)
      subject.then
    end

    it 'calls defer when fulfilled' do
      subject.then
      expect(subject).to receive(:defer)
      subject.fulfill
    end

    it 'calls defer when rejected' do
      subject.then
      expect(subject).to receive(:defer)
      subject.reject
    end

    # REVIEW: Consider moving context 'if/when subject is fulfilled/rejected' into this level

    context 'with no callbacks' do

      before(:each) { @return_promise = subject.then }

      it 'returns a promise that fulfills when subject fulfills' do
        subject.fulfill(:value)

        expect_fulfillment(@return_promise, with: :value)
      end

      it 'returns a promise that rejects when subject rejects' do
        subject.reject(:value)

        expect_rejection(@return_promise, with: :value)
      end

    end

    context 'with fulfill callback' do

      it 'allows registering fulfill callback by passing a block' do
        return_promise = subject.then do
          PurePromise.fulfill(:value)
        end

        subject.fulfill

        expect_fulfillment(return_promise, with: :value)
      end

      context 'when callback is registered while pending' do

        it 'fullfills to the value that the return promise of the callback fullfills to' do
          return_promise = subject.then(proc {
            PurePromise.fulfill(:value)
          })

          subject.fulfill

          expect_fulfillment(return_promise, with: :value)

        end

        it 'rejects to the value that the return promise of the callback rejects to' do
          return_promise = subject.then(proc {
            PurePromise.reject(:value)
          })
          subject.fulfill

          expect_rejection(return_promise, with: :value)
        end

      end

      context 'when callback is registered after fulfillment' do
        before(:each) { subject.fulfill }

        it 'fullfills to the value that the return promise of the callback fullfills to' do
          return_promise = subject.then(proc {
            PurePromise.fulfill(:value)
          })

          expect_fulfillment(return_promise, with: :value)
        end

        it 'rejects to the value that the return promise of the callback rejects to' do
          return_promise = subject.then(proc {
            PurePromise.reject(:value)
          })

          expect_rejection(return_promise, with: :value)
        end
      end

    end

    context 'with reject callback' do

      context 'when callback is registered while pending' do

        it 'fullfills to the value that the return promise of the callback fullfills to' do
          return_promise = subject.then(proc{}, proc {
            PurePromise.fulfill(:value)
          })

          subject.reject

          expect_fulfillment(return_promise, with: :value)

        end

        it 'rejects to the value that the return promise of the callback rejects to' do
          return_promise = subject.then(proc{}, proc {
            PurePromise.reject(:value)
          })
          subject.reject

          expect_rejection(return_promise, with: :value)
        end

      end

      context 'when callback is registered after rejection' do
        before(:each) { subject.reject }

        it 'fullfills to the value that the return promise of the callback fullfills to' do
          return_promise = subject.then(proc{}, proc {
            PurePromise.fulfill(:value)
          })

          expect_fulfillment(return_promise, with: :value)
        end

        it 'rejects to the value that the return promise of the callback rejects to' do
          return_promise = subject.then(proc{}, proc {
            PurePromise.reject(:value)
          })

          expect_rejection(return_promise, with: :value)
        end
      end
    end

  end

  describe '#catch' do

    it 'is called on rejected promise' do
      subject.reject(:value)

      callback = proc { PurePromise.fulfill }

      expect(callback).to receive(:call).with(:value).and_call_original

      subject.catch(&callback)
    end

    it 'returns a promise that fulfills with original' do
      promise = subject.catch { PurePromise.fulfill }

      expect_fulfillment(promise, with: :value) do
        subject.fulfill(:value)
      end
    end

    context 'with no callbacks' do

      before(:each) { @return_promise = subject.catch }

      it 'returns a promise that fulfills when subject fulfills' do
        subject.fulfill(:value)

        expect_fulfillment(@return_promise, with: :value)
      end

      it 'returns a promise that rejects when subject rejects' do
        subject.reject(:value)

        expect_rejection(@return_promise, with: :value)
      end

    end


  end

end