# Merritt UI Library

A library of static HTML components and CSS styles that make up the Merritt dashboard user interface.

This is a minimalist library consisting of HTML files, downloadable assets such as images and fonts,
and [SASS](https://sass-lang.com/) stylesheets in SCSS syntax.

## Toolkit

Compiling SCSS to CSS requires [sassc](https://github.com/sass/sassc) or
[dart-sass](https://github.com/sass/dart-sass). It may or may not work with (deprecated)
[Ruby Sass](https://sass-lang.com/ruby-sass).

## Demo

To build a demo of the UI library in `public/demo`, use the `:ui:demo` Rake task:

```
$ bundle exec rake ui:demo
Processing source files from /Users/david/Work/mrt-dashboard/ui-library
                   to target /Users/david/Work/mrt-dashboard/public/demo

Checking SCSS style:
  sass-lint --config ui-library/scss/.sass-lint.yml 'ui-library/scss/*.scss' -v -q --max-warnings=0

Clearing target directory

Processing files
  Copying ui-library/index.html to public/demo/index.html
  (...)
  Copying ui-library/images/logos/cts-logo.svg to public/demo/images/logos/cts-logo.svg
  (...)
  Compiling ui-library/scss/home.scss to public/demo/css/home.css
  (...)
  Copying ui-library/fonts/OpenSans-Regular-Cyrillic-Ext.woff2 to public/demo/fonts/OpenSans-Regular-Cyrillic-Ext.woff2
  (...)
```

The demo can then be viewed at `/demo/` when the application is running (e.g. 
[http://localhost:3000/demo/](http://localhost:3000/demo/))

> **⚠️** The `public/demo` directory is **erased** each time this task runs, so don’t
> put anything in it that you care about. (It’s also excluded in `.gitignore`.) 

## Production

To compile SCSS files to `public/stylesheets` and copy images and fonts to `public/images` and
`public/fonts`, use the `:ui:prod` Rake task:

```
$ bundle exec rake ui:prod
Processing source files from /Users/david/Work/mrt-dashboard/ui-library
                   to target /Users/david/Work/mrt-dashboard/public

Checking SCSS style:
  sass-lint --config ui-library/scss/.sass-lint.yml 'ui-library/scss/*.scss' -v -q --max-warnings=0

Processing files
  Copying ui-library/images/logos/cts-logo.svg to public/images/logos/cts-logo.svg
  (...)
  Compiling ui-library/scss/home.scss to public/stylesheets/home.css
  (...)
  Copying ui-library/fonts/OpenSans-Regular-Cyrillic-Ext.woff2 to public/fonts/OpenSans-Regular-Cyrillic-Ext.woff2
  (...)
```

## `sass-lint` usage

[`sass-lint`](https://github.com/sasstools/sass-lint/) is an [NPM package](https://www.npmjs.com/package/sass-lint)
that provides style checks for SASS files, analogous to [RuboCop](https://github.com/rubocop-hq/rubocop) for Ruby.

If `sass-lint` is available on the `$PATH`, the `:uidemo` Rake task will run it against the UI library SASS files,
using the configuration in [scss/.sass-lint.yml](scss/.sass-lint.yml)

To manually check the UI library SASS files with `sass-lint`, run the following command from the project root:

```
sass-lint --config ui-library/scss/.sass-lint.yml 'ui-library/scss/*.scss' -v
```

## Troubleshooting

### Demo images are not visible

Make sure the demo URL ends in a slash (i.e. `/demo/`, not `/demo`). Apache will silently add
the slash; Rails won’t.
