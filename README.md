[![Build Status](https://travis-ci.org/cameron-martin/pure_promise.svg?branch=master)](https://travis-ci.org/cameron-martin/pure_promise)
[![Code Climate](https://codeclimate.com/github/cameron-martin/pure_promise/badges/gpa.svg)](https://codeclimate.com/github/cameron-martin/pure_promise)

# PurePromise

My promises library. It tries to be as close to the Promises/A+ spec as possible, with one exception:

__A promise callback _must_ return a promise__

This makes it slightly more verbose, but it gives them some nice properties. I'll explain them here later.

Influenced by [promise.rb][2], the [Promises/A+ spec][3], and browsers' implementations of promises (for the stuff that's not `#then`).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pure_promise'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pure_promise

## Usage

### Making them asynchronous

PurePromise is agnostic about what you use to make them asynchronous. Just over-write the defer method, and you're done.

Note: The defer method does not have to yield in the order in which defer was called,
it just has to yield some time in the future.

```ruby
class EMPromise < PurePromise
  def defer
    EM.next_tick { yield }
  end
end
```

### Creating promises

```ruby
# Create a fulfilled promise
PurePromise.fulfill(:value)
PurePromise.fulfill

# Create a rejected promise
PurePromise.reject(:value)
PurePromise.reject

# Create a pending promise
PurePromise.new

# Create a promise which fulfills or rejects when fulfill or reject are called.
PurePromise.new do |fulfill, reject|
  if something?
    fulfill.call(:value)
  else
    reject.call(:error)
  end
end

# Create a promise with fulfills/rejects when thenable fulfills/rejects
PurePromise.resolve(thenable)

# Create a promise which is rejected to an exception object, with backtrace properly set.
PurePromise.error # #<RuntimeError: RuntimeError>
PurePromise.error('message') # #<RuntimeError: message>
PurePromise.error(TypeError, 'message') # #<TypeError: message>
PurePromise.error(TypeError.new('message')) # #<TypeError: message>
```

### Mutating promises

A promise can only be mutated once. Once it has transitioned from pending, the value cannot be changed.

```ruby
promise = PurePromise.new

# It is recommended to pass a block to new for fulfilling and rejecting promises,
# as this normally makes your code more clear
promise.fulfill(:value)
promise.reject(:value)

# Make promise take on the form of thenable
# This can be any object that implements a semi-compliant then method,
# as described in the Promises/A+ spec
promise.resolve(thenable)

```

### Accessing promises

The only way to access a promise's value is through the then/catch methods.

Each callback __must__ evaluate to a promise. If the action in the callback succeeds, return `PurePromise.fulfill`,
otherwise return `PurePromise.reject`.

`then` and `catch` always return a promise, which fulfills or rejects to the value of the promise returned from the callback when it is executed.

If a callback raises an error, the promise returned by `then` or `catch` will be rejected with the error as the value.

```ruby

# Attach a fulfillment callback
PurePromise.fulfill(:some_value).then do |value|
  puts value.inspect
  PurePromise.fulfill
end
# :some_value

# Attach a rejection callback
PurePromise.error.catch do |error|
  puts error.inspect
  PurePromise.fulfill
end
# #<RuntimeError: RuntimeError>

# Attach both
PurePromise.fulfill(:some_value).then(proc { |value|
  puts value.inspect
  PurePromise.fulfill
}, proc { |error|
  puts error.inspect
  PurePromise.fulfill
})

```

## Shortcomings addressed

This isn't having a dig at anyone else's work, these are just the reasons why I wanted to create my own promises library.
I could have got a lot of things wrong too, and I'd love to hear about them in the issues section.

### In Promises/A+ Spec

* You cannot wrap anything that implements a `then` method in a promise.
  This bit me when wanting to pass around a [faye client][1] in a promise system - and it took me forever to debug.
  PurePromise addresses this by forcing you to return a promise from your callbacks.

### In Promise.rb

* IMO, being able to retrieve the value of the promise through an accessor is wrong.
  What do you return when the promise is pending and _has no value_? Nil? But nil is a valid value for a promise,
  creating ambiguity.

## Design goals
* Address the above shortcomings.
* Limit the public api to as small as possible (then, fulfill, reject, resolve).
  Everything else should just be convenience methods on top of these.

## TODO

* Implement Promise.all method
* DRY up specs; they are pretty verbose atm.
* Get 100% mutation coverage

## Contributing

1. Fork it ( https://github.com/cameron-martin/pure_promise/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[1]: http://faye.jcoglan.com/browser.html
[2]: https://github.com/lgierth/promise.rb
[3]: http://promisesaplus.com/
