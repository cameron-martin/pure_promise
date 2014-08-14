# PurePromise

My promises library. It tries to be as close to the Promises/A+ spec as possible, with one exception:

__A promise callback _must_ return a promise__

This makes it slightly more verbose, but

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

## TODO

* Implement the thenable -> PurePromise part of the promise resolution procedure
* Add usage instructions
* Hide `#value` by using [this nifty trick][1].
* Consider removing the `pending?`, `fulfilled?` and `rejected?` methods; is allowing inspecting a promise's state wrong?
* DRY up specs; they are pretty verbose atm.
* Get 100% mutation coverage
* Release gem

## Contributing

1. Fork it ( https://github.com/cameron-martin/pure_promise/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[1]: http://kylecronin.me/blog/2012/4/22/a-clever-ruby-equality-trick.html
