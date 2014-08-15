describe PurePromise::Coercer do

  subject { PurePromise::Coercer.new(thenable, PurePromise) }

  context 'with non-thenable' do
    let(:thenable) { Object.new }

    describe '.is_thenable?' do
      it 'is false' do
        expect(PurePromise::Coercer.is_thenable?(thenable)).to eq(false)
      end
    end

    describe '#initialize' do
      it 'raises TypeError' do
        expect { subject }.to raise_error(TypeError, 'Can only coerce a thenable')
      end
    end

  end

  context 'with PurePromise' do
    describe '#coerce' do
      let(:thenable) { PurePromise.new }

      it 'returns promise' do
        expect(subject.coerce).to equal(thenable)
      end

    end
  end

  context 'with conformant thenable' do

    let(:thenable) { Thenable::Conformant.new }

    describe '.is_thenable?' do
      it 'is true' do
        expect(PurePromise::Coercer.is_thenable?(thenable)).to eq(true)
      end
    end

    describe '#coerce' do

      it 'returns a promise' do
        expect(subject.coerce).to be_a(PurePromise)
      end

      it 'fulfills when callback passed to then is called' do
        promise = subject.coerce

        expect_fulfillment(promise, with: :value) do
          thenable.fulfill(:value)
        end
      end

      it 'rejects when callback passed to then is called' do
        promise = subject.coerce

        expect_rejection(promise, with: :value) do
          thenable.reject(:value)
        end
      end

      it 'ignores subsequent calls of reject callback' do
        promise = subject.coerce

        thenable.reject(:value)
        thenable.reject(:other_value)

        expect_rejection(promise, with: :value)
      end

      it 'ignores subsequent calls of fulfill callback' do
        promise = subject.coerce

        thenable.fulfill(:value)
        thenable.fulfill(:other_value)

        expect_fulfillment(promise, with: :value)
      end

    end
  end

  context 'with early erroring thenable' do
    let(:thenable) { Thenable::EarlyErroring.new(error) }

    let(:error) { RuntimeError.new('Some error') }

    describe '#coerce' do
      it 'rejects promise with error' do
        promise = subject.coerce

        expect_rejection(promise, with: error)
      end
    end

  end

  context 'with late erroring thenable' do
    let(:thenable) { Thenable::LateErroring.new(:value, error) }

    let(:error) { RuntimeError.new }

    describe '#coerce' do
      it 'rejects promise with error' do
        promise = subject.coerce

        expect_fulfillment(promise, with: :value)
      end
    end

  end



end