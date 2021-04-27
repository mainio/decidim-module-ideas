# Decidim::Ideas

[![Build Status](https://github.com/mainio/decidim-module-ideas/actions/workflows/ci_ideas.yml/badge.svg)](https://github.com/mainio/decidim-module-ideas/actions)

**NOTE: This module is currently work in progress, THERE CAN STILL BE BUGS**

Currently this module depends on these changes being in the core:

https://github.com/decidim/decidim/pull/6340

Please port these changes to your instance before trying this out.

A [Decidim](https://github.com/decidim/decidim) module for creating ideas in
participatory budgeting. The base of the ideas component is extremely similar to
the core proposals module which you should primarily use if you want to
implement participatory budgeting as it is designed in Decidim by default.
The ideas module is more limited in features but has a higher focus on achieving
a better user experience for working with ideas.

The development of this module began because the City of Helsinki that collected
a lot of user feedback from the ideation phase from their first round of the
city wide participatory budgeting. This feedback led to a new rehauled design
for the ideation phase which was the basis for this module. The main focus is to
streamline the user experience and serve the identified additional needs from
that feedback and from the city.

There are some key differences between ideas and proposals that include:

- Simplified user experience and cut down features, focusing only what is
  relevant for the idea creation phase
- Improved creation UI for the ideas which contains less steps than the
  proposals module has and provides easier to use UI components
- Improved map functionality
- Ability to edit/collaborate on the ideas while the idea creation phase is
  ongoing

The development has been funded by the
[City of Helsinki](https://www.hel.fi/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "decidim-ideas"
```

And then execute:

```bash
$ bundle
$ bundle exec rails decidim_favorites:install:migrations
$ bundle exec rails decidim_feedback:install:migrations
$ bundle exec rails decidim_ideas:install:migrations
$ bundle exec rails db:migrate
```

## Usage

TBD

## Contributing

See [Decidim](https://github.com/decidim/decidim).

### Testing

To run the tests run the following in the gem development path:

```bash
$ bundle
$ DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rake test_app
$ DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rspec
```

Note that the database user has to have rights to create and drop a database in
order to create the dummy test app database.

In case you are using [rbenv](https://github.com/rbenv/rbenv) and have the
[rbenv-vars](https://github.com/rbenv/rbenv-vars) plugin installed for it, you
can add these environment variables to the root directory of the project in a
file named `.rbenv-vars`. In this case, you can omit defining these in the
commands shown above.

### Test code coverage

If you want to generate the code coverage report for the tests, you can use
the `SIMPLECOV=1` environment variable in the rspec command as follows:

```bash
$ SIMPLECOV=1 bundle exec rspec
```

This will generate a folder named `coverage` in the project root which contains
the code coverage report.

### Localization

If you would like to see this module in your own language, you can help with its
translation at Crowdin:

https://crowdin.com/project/decidim-ideas

## License

See [LICENSE-AGPLv3.txt](LICENSE-AGPLv3.txt).
