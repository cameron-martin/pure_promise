describe PurePromise do

  subject { PurePromise.new }

  let(:fulfill_callback) { double('fulfill_callback').as_null_object }
  let(:reject_callback) { double('reject_callback').as_null_object }

  describe '#initiailize' do
    it 'yields fullfill and reject methods if block given' do
      expect do |b|
        PurePromise.new(&b)
      end.to yield_with_args(
                 a_bound_method_of(PurePromise.instance_method(:fulfill)),
                 a_bound_method_of(PurePromise.instance_method(:reject))
             )
    end
  end

  # REVIEW: Maybe just test delegation here.
  describe '.fulfill' do

    it 'is a promise' do
      expect(PurePromise.fulfill).to be_an_instance_of(subject.class)
    end

    it 'is fulfilled with value' do
      expect_fulfillment(PurePromise.fulfill(:value), with: :value)
    end
  end

  describe '.reject' do
    it 'is a promise' do
      expect(PurePromise.reject).to be_an_instance_of(subject.class)
    end

    it 'is rejected with value' do
      expect_rejection(PurePromise.reject(:value), with: :value)
    end
  end

  describe '#fulfill' do
    it 'calls fulfill callback when promise transitions to fulfilled' do
      expect_fulfillment(subject, with: :value) do
        subject.fulfill(:value)
      end
    end

    it 'is fulfilled' do
      subject.fulfill
      expect(subject).to be_fulfilled
    end

    it 'should raise error if fulfill twice' do
      subject.fulfill
      expect { subject.fulfill }.to raise_error(PurePromise::MutationError, 'You can only fulfill a pending promise')
    end

    it 'should raise error if fulfilled after being rejected' do
      subject.reject
      expect { subject.fulfill }.to raise_error(PurePromise::MutationError, 'You can only fulfill a pending promise')
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
      expect(subject).to be_rejected
    end

    it 'should raise error if rejected twice' do
      subject.reject
      expect { subject.reject }.to raise_error(PurePromise::MutationError, 'You can only reject a pending promise')
    end

    it 'should raise error if rejected after being fulfilled' do
      subject.fulfill
      expect { subject.reject }.to raise_error(PurePromise::MutationError, 'You can only reject a pending promise')
    end

    it 'returns self' do
      expect(subject.reject).to eq(subject)
    end
  end

  describe '#pending?' do
    it 'is true when pending' do
      expect(subject).to be_pending
    end

    it 'is false when fulfilled' do
      subject.fulfill

      expect(subject).to_not be_pending
    end

    it 'is false when rejected' do
      subject.reject

      expect(subject).to_not be_pending
    end
  end

  describe '#fulfilled?' do
    it 'is true when fulfilled' do
      subject.fulfill

      expect(subject).to be_fulfilled
    end

    it 'is false when rejected' do
      subject.reject

      expect(subject).to_not be_fulfilled
    end

    it 'is false when pending' do
      expect(subject).to_not be_fulfilled
    end
  end

  describe '#rejected?' do
    it 'is true when rejected' do
      subject.reject

      expect(subject).to be_rejected
    end

    it 'is false when fulfilled' do
      subject.fulfill

      expect(subject).to_not be_rejected
    end

    it 'is false when pending' do
      expect(subject).to_not be_rejected
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

    context 'with no callbacks' do

      it 'returns a promise that resolves when subject resolves' do
        return_promise = subject.then

        subject.fulfill(:value)

        expect_fulfillment(return_promise, with: :value)
      end

      it 'returns a promise that rejects when subject rejects' do
        return_promise = subject.then

        subject.reject(:value)

        expect_rejection(return_promise, with: :value)
      end

    end

    context 'with fulfill callback' do

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

end