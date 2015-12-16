# Rails app


## Getting Started

After you have cloned this repo, run this setup script to set up your machine
with the necessary dependencies to run and test this app:

    % ./bin/setup

It assumes you have a machine equipped with Ruby, Postgres, etc. If not, set up
your machine with [this script].

[this script]: https://github.com/thoughtbot/laptop

After setting up, you can run the application using [foreman]:

    % foreman start

If you don't have `foreman`, see [Foreman's install instructions][foreman]. It
is [purposefully excluded from the project's `Gemfile`][exclude].

[foreman]: https://github.com/ddollar/foreman
[exclude]: https://github.com/ddollar/foreman/pull/437#issuecomment-41110407


## Deploying to Heroku

This project is ready to deploy to [Heroku](https://heroku.com), still before that
please install plugins for mongodb, email & make sure these variables are set
in your app ENV:

    MONGODB_URI
    ASSET_HOST
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    FOG_DIRECTORY
    HOST
    SMTP_ADDRESS
    SMTP_DOMAIN
    SMTP_PASSWORD
    SMTP_USERNAME


Good luck, have fun, program well and program in style!
