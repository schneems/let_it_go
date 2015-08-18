# Let It Go

Frozen string literals can save time and memory when used correctly. This library looks for common places that can easily accept frozen string literals and lets you know if a non-frozen string is being used instead so you can speed up your programs.

For more info on the relationship betwen speed, objects, and memory in Ruby Check out [How Ruby Uses Memory](http://www.schneems.com/2015/05/11/how-ruby-uses-memory/).

Note: This library only works with Ruby files on disk, and not with interactive sessions like `irb`. Why? Because intercepting arguments to c defined methods isn't possible [Attempt 1](http://stackoverflow.com/questions/30512945/programmatically-alias-method-that-uses-global-variable) [Attempt 2](http://stackoverflow.com/questions/30584454/get-method-arguments-using-rubys-tracepoint).

## What is a Frozen String Literal?

This is a frozen string literal:

```ruby
"foo".freeze
```

The `freeze` method is a way to tell  the Ruby interpreter that we will not modify that string in the future. When we do this, the Ruby interpreter only ever has to create one object that can be re-used instead of having to create a new string each time. This is how we save CPU cycles. Passing frozen strings to methods like `String#gsub` that do not modify their arguments is best practice when possible:

```ruby
matchdata.captures.map do |e|
  e.gsub(/_|,/, '-'.freeze)
end
```

## Installation

Requires Ruby 2.0+

Add this line to your application's Gemfile:

```ruby
gem 'let_it_go', group: :development
```

And then execute:

    $ bundle

It's really important you don't run this in production, it would really slow stuff down.


## Middleware Use

You can profile method calls during a request by using a middleware.


```ruby
# config/initializers/let_it_go.rb

if defined?(LetItGo::Middleware::Olaf)
  Rails.application.config.middleware.insert(0, LetItGo::Middleware::Olaf)
end
```

Now every time a page is rendered, you'll get a list of un-frozen methods in your standard out.

## Direct Use

Anywhere you want to check for non-frozen string use call:

```ruby
LetItGo.record do
  "foo".gsub(/f/, "")
end.print

## Un-Fozen Hotspots
#  1: Method: String#gsub [(irb):2:in `block in irb_binding']
```

Each time the same method is called it is counted

```ruby
LetItGo.record do
  99.times { "foo".gsub(/f/, "") }
end.print

## Un-Fozen Hotspots
#  99: Method: String#gsub [(irb):6:in `block (2 levels) in irb_binding']
```

When you're running this against a file, `LetItGo` will try to parse the calling line to determine if a string literal was used.

```
$ cat <<  EOF > foo.rb
  require 'let_it_go'

  LetItGo.record do
    "foo".gsub(/f/, "")
  end.print
EOF
$ ruby foo.rb
## Un-Fozen Hotspots
  1: Method: String#gsub [foo.rb:4:in `block in <main>']
```

If you try again with a string variable or a modified string (anything not a string literal) it will be ignored

```
$ cat <<  EOF > foo.rb
  require 'let_it_go'

  LetItGo.record do
    "foo".gsub(/f/, "".downcase) # freezing downcase would not help with memory or speed here
  end.print
EOF
$ ruby foo.rb
## Un-Fozen Hotspots
  (none)
```

## Watching Frozen (methods)

For a list of all methods that are watched check in lib/let_it_go/core_ext. You can manually add your own by using `LetItGo.watch_frozen`. For example `[].join("")` is a potential hotspot. To watch this method we would call

```ruby
LetItGo.watch_frozen(Array, :join, positions: [0])
```

The positions named argument is an array containing the indexes of the method arguments you want to watch. In this case `join` only takes one method argument, so we are only watching the first one (index of 0). If there are other common method invocations that can ALWAYS take in a frozen string (i.e. they NEVER modify the string argument) then please submit a PR to this library by adding it to `lib/let_it_go/core_ext`. Please add a test to the corresponding spec file.

## How

This extremely convoluted library works by watching all method calls using [TracePoint](http://ruby-doc.org/core-2.2.2/TracePoint.html) to see when a method we are watching is called. Since we [cannot use TracePoint to get all method arguments](http://stackoverflow.com/questions/30584454/get-method-arguments-using-rubys-tracepoint) we instead resort to parsing Ruby code on disk to see if a string literal is used. The parsing functionality is achieved by reading in the line of the caller and parsing it with [Ripper](http://ruby-doc.org/stdlib-2.2.2/libdoc/ripper/rdoc/Ripper.html) which is then translated by lib/let_it_go/wtf_parser.rb. It probably has bugs, and it won't work with weirly formatted or multi line code.

If you can think of a better way, please open up an issue and send me a proof of concept. I know what you're thinking and no, [programatically aliasing methods won't work for 100% of the time](http://stackoverflow.com/questions/30512945/programmatically-alias-method-that-uses-global-variable).

Note: This method fails for any Ruby code that can't be parsed in 1 line. For example:

```
query = <<-SQL % known_coder_types.join(", ")
```

and

```
(attr[0] == :html && attr[1] == :attr && options[:hyphen_attrs].include?(attr[2]) &&
```

Are not valid, complete Ruby instructions. That being said this lib is still relevant. To see what you're not able to parse, run with `ENV['LET_IT_GO_RECORD_FAILED_CODE']`




## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/let_it_go/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


## TODO

- Global operators != && == (maybe it's good enough to only track calls to string)
- Watch receivers such as "foo".eq(variable)
