# Character

[![Build Status](https://travis-ci.org/slate-studio/chr.svg?branch=master)](https://travis-ci.org/slate-studio/chr)


*Powerful responsive javascript CMS for apps.*


## Quick Start

Application setup:

```coffee
#= require jquery
#= require chr

postsConfig = (data) ->
  itemTitleField: 'title'
  arrayStore: new RestArrayStore({
    path:     '/admin/posts'
    sortBy:   'title'
  })
  formSchema:
    title: { type: 'string' }
    body:  { type: 'text'   }

$ ->
  config =
    modules:
      posts: postsConfig()

  chr.start(config)
```

Styles setup:

```scss
@import "normalize-rails";
@import "chr";
```


## Documentation

* [Rails Setup](docs/rails.md)
* [Bootstrap Data](docs/bootstrap.md)
* [Tests](docs/tests.md)

More documentation and samples comming soon...


## Notes

1. Consider replace ```slip.js``` with [sortable.js](https://github.com/RubaXa/Sortable)


## Character family:

- [Character](https://github.com/slate-studio/chr): Powerful responsive javascript CMS for apps
- [Mongosteen](https://github.com/slate-studio/mongosteen): An easy way to add RESTful actions for Mongoid models
- [Inverter](https://github.com/slate-studio/inverter): An easy way to connect Rails templates content to Character CMS
- [Loft](https://github.com/slate-studio/loft): Media assets manager for Character CMS


## License

Copyright © 2015 [Slate Studio, LLC](http://slatestudio.com). Character is free software, and may be redistributed under the terms specified in the [license](LICENSE.md).


## About Slate Studio

[![Slate Studio](https://slate-git-images.s3-us-west-1.amazonaws.com/slate.png)](http://slatestudio.com)

Character is maintained and funded by [Slate Studio, LLC](http://slatestudio.com). Tweet your questions or suggestions to [@slatestudio](https://twitter.com/slatestudio) and while you’re at it follow us too.




