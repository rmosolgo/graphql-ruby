#!/usr/bin/env node
var parseArgs = require('minimist')
var argv = parseArgs(process.argv.slice(2))

if (argv.help || argv.h) {
  console.log(`usage: graphql-ruby-client sync <options>

  Read .graphql files and push the contained
  operations to a GraphQL::Pro::OperationStore

required arguments:
  --url=<endpoint-url>    URL where data should be POSTed
  --client=<client-name>  Identifier for this client application

optional arguments:
  --path=<path>                   Path to .graphql files (default is "./**/*.graphql")
  --outfile=<generated-js-file>   Target file for generated JS code
  --key=<key>                     HMAC authentication key
  --mode=<mode>                   Treat files like a certain kind of project:
                                    relay: treat files like relay-compiler output
                                    project: treat files like a cohesive project (fragments are shared, names must be unique)
                                    file: treat each file like a stand-alone operation

                                  By default, this flag is set to:
                                    - "relay" if "__generated__" in the path
                                    - otherwise, "project"
  --quiet                         Suppress status logging
  --help                          Print this message
`)
} else {
  var commandName = argv._[0]

  if (commandName !== "sync") {
    console.log("Only `graphql-ruby-client sync` is supported")
  } else {
    var sync = require("./sync")
    var result = sync({
      path: argv.path,
      url: argv.url,
      client: argv.client,
      outfile: argv.outfile,
      secret: argv.secret,
      mode: argv.mode,
      quiet: argv.hasOwnProperty("quiet"),
    })

    if (result instanceof Promise){
      result.then(function(res) {
        if (res === false) {
          process.exit(1)
        }
      })
    } else if (result === false) {
      process.exit(1)
    }
  }
}
