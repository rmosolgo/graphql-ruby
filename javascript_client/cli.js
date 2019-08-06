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
  --outfile=<generated-filename>  Target file for generated code
  --outfile-type=<type>           Target type for generated code (default is "js")
  --key=<key>                     HMAC authentication key
  --mode=<mode>                   Treat files like a certain kind of project:
                                    relay: treat files like relay-compiler output
                                    project: treat files like a cohesive project (fragments are shared, names must be unique)
                                    file: treat each file like a stand-alone operation

                                  By default, this flag is set to:
                                    - "relay" if "__generated__" in the path
                                    - otherwise, "project"
  --add-typename                  Automatically adds the "__typename" field to your queries
  --quiet                         Suppress status logging
  --verbose                       Print debug output
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
      outfileType: argv["outfile-type"],
      secret: argv.secret,
      mode: argv.mode,
      addTypename: argv["add-typename"],
      quiet: argv.hasOwnProperty("quiet"),
      verbose: argv.hasOwnProperty("verbose"),
    })

    result.then(function(res) {
      process.exit(0)
    }).catch(function(_err) {
      // The error is logged by the function
      process.exit(1)
    })
  }
}
