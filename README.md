[![Build Status](https://travis-ci.org/cameron-martin/pure_promise.svg?branch=master)](https://travis-ci.org/cameron-martin/pure_promise)

# PurePromise

My promises library. It tries to be as close to the Promises/A+ spec as possible, with one exception:

__A promise callback _must_ return a promise__

This makes it slightly more verbose, but it has some nice properties. I'll explain them here later.

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

TODO: Write usage instructions here

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

* Add usage instructions
* Add PurePromise.raise method, which created a rejected promise with an exception, with backtrace set properly.
* DRY up specs; they are pretty verbose atm.
* Get 100% mutation coverage
* Add more rubies to travis build matrix.
* Release gem

## Contributing

1. Fork it ( https://github.com/cameron-martin/pure_promise/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[1]: http://faye.jcoglan.com/browser.html
[2]: https://github.com/lgierth/promise.rb
[3]: http://promisesaplus.com/