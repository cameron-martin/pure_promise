RSpec::Matchers.define :be_a_bound_method_of do |unbound_method|
  match do |bound_method|
    bound_method.unbind == unbound_method
  end
end

RSpec::Matchers.alias_matcher :a_bound_method_of, :be_a_bound_method_of

# TODO: Fix composable error message for this.
RSpec::Matchers.define :be_an_error do |error_class=nil, message=nil|
  match do |error|
    [
        error.is_a?(error_class || RuntimeError),
        @backtrace.nil?  || (error.backtrace == @backtrace),
        message.nil?     || (error.message   == message)
    ].all?
  end

  chain :with_backtrace do |backtrace|
    @backtrace = backtrace
  end

  #failure_message do |error|
  #  "expected error to have backtrace #{expected_backtrace.inspect}, actually got #{error.backtrace.inspect}"
  #end
end

RSpec::Matchers.alias_matcher :an_error, :be_an_error