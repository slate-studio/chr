# Character [![Build Status](https://travis-ci.org/slate-studio/chr.svg?branch=master)](https://travis-ci.org/slate-studio/chr)
[![Code Climate](https://codeclimate.com/github/slate-studio/chr/badges/gpa.svg)](https://codeclimate.com/github/slate-studio/chr)

Character is powerful responsive javascript-based CMS for website and applications used by [Slate Studio](https://www.slatestudio.com).


## Quick Start

First install the character gem:

    gem install chr

Then run:

    chr projectname

This will create a Rails app in `projectname` using the latest version of Rails with character CMS integrated.

Go to the created project folder. To create an admin user, open a rails console with `rails c` and execute the following line :

    AdminUser.create(email: 'admin@example.com', password: 'password', name: 'admin')

Start the development server with `rails s`. Go to `localhost:3000/admin` and login with the credentials you used above. You see default character initial configuration, it gives `file uploader`, `admins` and `redirects` modules out of the box as shown on screenshot below.

![Default Character Setup Demo](https://raw.github.com/slate-studio/chr/master/docs/demo.png)

Project is ready to deploy to [Heroku](https://www.heroku.com). Take a look at projects `README.md` to add plugins, create S3 bucket and setup `ENV` settings required to run the app. After deploy first admin has to be created via `heroku run console`:

    AdminUser.create(email: 'admin@example.com', password: 'password', name: 'admin')


## Connect Models


## Character Family:

- [Character](https://github.com/slate-studio/chr): Powerful responsive javascript CMS for apps
- [Mongosteen](https://github.com/slate-studio/mongosteen): An easy way to add RESTful actions for Mongoid models
- [Inverter](https://github.com/slate-studio/inverter): An easy way to connect Rails templates content to Character CMS
- [Loft](https://github.com/slate-studio/loft): Media assets manager for Character CMS


## License

Copyright © 2015 [Slate Studio, LLC](http://slatestudio.com). Character is free software, and may be redistributed under the terms specified in the [license](LICENSE.md).


## About Slate Studio

[![Slate Studio](https://slate-git-images.s3-us-west-1.amazonaws.com/slate.png)](http://slatestudio.com)

Character is maintained and funded by [Slate Studio, LLC](http://slatestudio.com). Tweet your questions or suggestions to [@slatestudio](https://twitter.com/slatestudio) and while you’re at it follow us too.




