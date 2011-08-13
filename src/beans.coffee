fs     = require 'fs'
glob   = require 'glob'
path   = require 'path'
stitch = require 'stitch'
uglify = require 'uglify-js'
{exec} = require 'child_process'

# Defaults for package information.
defaults =
  browser: true
  browserPrefix: ''
  copyright: (new Date).getFullYear()
  license: ''

# Load package information from multiple sources.
loadInfo = ->
  # Load beans.json and add unset defaults.
  try
    info = JSON.parse(fs.readFileSync 'beans.json')
  catch e
    info = {}
  for key of defaults
    info[key] = defaults[key] unless info[key]?
  # Load package.json and override existing significant values.
  package = JSON.parse(fs.readFileSync 'package.json')
  for key in ['author', 'name', 'description', 'version']
    unless package[key]?
      throw new Error "Section `#{key}' required in package.json."
    info[key] = package[key]
  # Source header for browser bundles.
  info.browserName = info.browserPrefix + info.name
  if info.license != ''
    license = "Released under the #{info.license}"
  else
    license = 'Contact author for licensing information'
  info.header = """
  /**
   * #{info.browserName} #{info.version} (browser bundle)
   * #{info.description}
   *
   * Copyright (c) #{info.copyright} #{info.author}
   * #{license}
   */
  """
  # Source footer for browser bundles.
  info.footer = "this.#{info.browserName} = require('#{info.browserName}');"
  info

# Run the specified function if a given executable is installed,
# or print a notice.
ifInstalled = (executable, fn) ->
  exec 'which ' + executable, (err) ->
    return fn() unless err
    console.log "This task needs `#{executable}' to be installed and in PATH."

# Try to execute a shell command or fail with an error.
tryExec = (cmd) ->
  proc = exec cmd, (err) ->
    throw err if err
  proc.stdout.on 'data', (data) ->
    process.stdout.write data.toString()

# Safely make a directory with default permissions.
makeDir = (dir) ->
  fs.mkdirSync dir, 0755 unless path.existsSync dir

# Check command argument.
knownTarget = (command, target, targets) ->
  if targets.indexOf(target) == -1
    console.log "Unknown #{command} target `#{target}'."
    console.log "Try one of: #{targets.join ', '}."
    return false
  true

# Compile all CoffeeScript sources for Node.
buildNode = (watch) ->
  ifInstalled 'coffee', ->
    tryExec "rm -rf lib && coffee -cb#{if watch then 'w' else ''} -o lib src"

# Use Stitch to create a browser bundle.
bundle = (info) ->
  stitch
    .createPackage
      paths: [fs.realpathSync 'src']
    .compile (err, src) ->
      throw err if err
      makeDir 'build'
      makeDir 'build/' + info.version
      dir = fs.realpathSync 'build/' + info.version
      fname = dir + '/' + info.browserName
      src += info.footer
      fs.writeFileSync fname + '.js', info.header + src
      fs.writeFileSync fname + '.min.js', info.header + uglify(src)
      tryExec "rm -f build/edge && ln -s #{dir}/ build/edge"

# Compile all CoffeeScript sources for the browser.
buildBrowser = (info, watch) ->
  bundle info
  if watch
    for file in glob.globSync 'src/**/*.coffee'
      fs.watchFile file, {persistent: true, interval: 500}, (curr, prev) ->
        if curr.mtime isnt prev.mtime
          bundle info

# Compile CoffeeScript source for Node and browsers.
build = ->
  info = loadInfo()
  buildNode()
  buildBrowser info if info.browser

# Remove generated directories to allow for a clean build
# or just tidy things up.
clean = (target) ->
  target ?= 'all'
  return unless knownTarget 'clean', target, ['build', 'docs', 'all']
  switch target
    when 'build' then tryExec 'rm -rf {build,lib}'
    when 'docs' then tryExec 'rm -rf docs'
    when 'all' then tryExec 'rm -rf {build,docs,lib}'

# Generate documentation files using Docco.
docs = ->
  ifInstalled 'docco', ->
    files = glob.globSync 'src/**/*.coffee'
    if files.length > 0
      tryExec 'docco "' + files.join('" "') + '"'

# Display command help.
help = ->
  for name, command of commands
    console.log "beans #{name}\t#{command[1]}"

# Get version information.
ver = JSON.parse(fs.readFileSync(__dirname + '/../package.json')).version

# Display version information.
version = ->
  console.log 'Beans ' + ver

# Build everything once, then watch for changes.
watch = ->
  info = loadInfo()
  buildNode true
  buildBrowser info, true if info.browser

# Supported commands list.
commands =
  build:   [ build   , 'Compile CoffeScript source for enabled targets.' ]
  clean:   [ clean   , 'Remove generated directories and tidy things up.' ]
  docs:    [ docs    , 'Generate documentation files using Docco.' ]
  help:    [ help    , 'Display help (this text).' ]
  version: [ version , 'Display current Beans version.' ]
  watch:   [ watch   , 'Build everything once, then watch for changes.' ]

# Run the console command.
run = ->
  args = process.argv.slice(2)
  if args.length == 0
    help()
  else if commands[args[0]]?
    commands[args[0]][0](args.slice(1)...)
  else
    console.log "Don't know how to `#{args[0]}'."

# Exports commands for in-Node use and command entry point.
module.exports =
  commands: commands
  run: run
  version: ver
