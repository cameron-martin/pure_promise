RSpec::Matchers.define :be_a_bound_method_of do |unbound_method|
  match do |bound_method|
    bound_method.unbind == unbound_method
  end
end

RSpec::Matchers.alias_matcher :a_bound_method_of, :be_a_bound_method_of