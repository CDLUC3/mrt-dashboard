# Merritt UI Library

A library of static HTML components and CSS styles that make up the Merritt dashboard user interface.

This is a minimalist library consisting of HTML files, downloadable assets such as images and fonts,
and [SASS](https://sass-lang.com/) stylesheets in SCSS syntax.

## Toolkit

Compiling SCSS to CSS requires [sassc](https://github.com/sass/sassc) or
[dart-sass](https://github.com/sass/dart-sass). (It may or may not work with (deprecated)
[Ruby Sass](https://sass-lang.com/ruby-sass).)

## Demo

To build a demo of the UI library in `public/demo`, use the `:uidemo` Rake task:

```
$ bundle exec rake uidemo
Clearing demo directory public/demo
Copying ui-library/home.html to public/demo/index.html
Copying ui-library/images/logos/cts-logo.svg to public/demo/images/logos/cts-logo.svg
Copying ui-library/images/logos/uc3-logo.svg to public/demo/images/logos/uc3-logo.svg
Copying ui-library/images/logos/escholarship-logo.svg to public/demo/images/logos/escholarship-logo.svg
Copying ui-library/images/logos/merritt-logo.svg to public/demo/images/logos/merritt-logo.svg
Copying ui-library/images/logos/calisphere-logo.svg to public/demo/images/logos/calisphere-logo.svg
Copying ui-library/images/logos/dash-logo.svg to public/demo/images/logos/dash-logo.svg
Copying ui-library/images/logos/ezid-logo.svg to public/demo/images/logos/ezid-logo.svg
Copying ui-library/images/logos/cdl-logo.svg to public/demo/images/logos/cdl-logo.svg
Compiling ui-library/scss/main.scss to public/demo/css/main.css
Copying ui-library/README.md to public/demo/README.md
Copying ui-library/fonts/KievitWeb.woff to public/demo/fonts/KievitWeb.woff
```

The demo can then be viewed at `/demo/` when the application is running (e.g. 
[http://localhost:3000/demo/](http://localhost:3000/demo/))

> **⚠️** The `public/demo` directory is **erased** each time this task runs, so don’t
> put anything in it that you care about. (It’s also excluded in `.gitignore`.) 

## Troubleshooting

### Demo images are not visible

Make sure the demo URL ends in a slash (i.e. `/demo/`, not `/demo`). Apache will silently add
the slash; Rails won’t.
