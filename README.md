# Beans

Beans is a set of tools for authoring Node modules written in
[CoffeeScript](http://jashkenas.github.com/coffee-script/), and optionally
targeting the browser. It does something that your own Cakefile would do,
except that you don't need to copy the same Cakefile around all of your
CoffeeScript projects.

## Usage

Beans is installed with npm. To have a global up-to-date `beans` binary in
your PATH, install globally:

    $ npm install beans -g

A less convenient, but more stable solution is to have a local version of
Beans, specific for each of your authored packages. To do this, first install
Beans globally, then run `beans scripts`. This will add Beans to your
`devDependencies` and register commands like `build` and `docs` in
package.json. These commands can then be run like so:

    $ npm run-script build

A list of available commands can be obtained by typing `beans help`. In
essence, Beans provides single and continuous build routines, a test runner
using [nodeunit](https://github.com/caolan/nodeunit), and documentation
generation using [Docco](http://jashkenas.github.com/docco/).

Principal command details:

* `beans build` issues a single build according to the project configuration
  (see below). If building for the browser is required, source is concatenated
  to a single file and a minified copy is created.
* `beans watch` starts a continuous build process, rebuilding when any
  CoffeeScript file is modified.
* `beans test` tries to do a successful build and runs nodeunit tests
  afterwards. Tests should be placed in the `test` folder (or its subfolders)
  and should have the `.test.coffee` extension, in order for Beans to locate
  them.
* `beans docs` generates documentation form source. This command expects Docco
  to be installed globally (`npm install docco -g`).
* `beans publish` rebuilds everything once and runs `npm publish`.

## Configuration

When building for the browser, Beans collects some information from
`package.json` and `beans.json` files. Create a `beans.json` file to override
the following build defaults:

    {
      "browser": true,
      "browserPrefix": "",
      "copyrightFrom": <current year>,
      "license": <unspecified>
    }

A sample `beans.json` file can be found in Beans own source, since Beans is
written in CoffeeScript and authored with itself, of course. Each key-value
pair is optional. In detail:

* `browser` is a switch to turn browser bundling on or off. The bundle is
  created using [Stitch](https://github.com/sstephenson/stitch) and minified
  with [UglifyJS](http://marijnhaverbeke.nl/uglifyjs).
* `browserPrefix` is used as a prefix for browser bundle filenames.
* `copyrightFrom` is a starting copyright year (e.g. 2010) that defaults to the
  current year. The browser bundle header comment will have a copyright notice
  featuring a span from the configured to year to current one (e.g. 2010-2011).
* `license` is the license you're using for the project. If a license is
  specified, it is displayes in the browser bundle header comment.
