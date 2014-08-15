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

## Design goals
* Limit the public api to as small as possible (then, fulfill, reject, resolve).
  Everything else should just be convenience methods on top of these.
* No introspection of the value that a promise has resolved to - access should be only allowed through then.
  Otherwise it creates problems with what it should return while pending. (Nil is still a value).

## TODO

* Implement `#catch` method
* Add usage instructions
* Catch errors raised in handlers.
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

[1]: http://kylecronin.me/blog/2012/4/22/a-clever-ruby-equality-trick.html
[2]: https://github.com/lgierth/promise.rb
[3]: http://promisesaplus.com/