#!/usr/bin/env node
import parseArgs from "minimist"
import sync from "./sync/index"
var argv = parseArgs(process.argv.slice(2))

if (argv.help || argv.h) {
  console.log(`usage: graphql-ruby-client sync <options>

  Read .graphql files and push the contained
  operations to a GraphQL::Pro::OperationStore

required arguments:
  --url=<endpoint-url>    URL where data should be POSTed
  --client=<client-name>  Identifier for this client application

optional arguments:
  --path=<path>                             Path to .graphql files (default is "./**/*.graphql")
  --outfile=<generated-filename>            Target file for generated code
  --outfile-type=<type>                     Target type for generated code (default is "js")
  --key=<key>                               HMAC authentication key
  --relay-persisted-output=<path>           Path to a .json file from "relay-compiler ... --persist-output"
                                              (Outfile generation is skipped by default.)
  --apollo-codegen-json-output=<path>       Path to a .json file from "apollo client:codegen ... --target json"
                                              (Outfile generation is skipped by default.)
  --apollo-android-operation-output=<path>  Path to a .json file from Apollo-Android's "generateOperationOutput" feature.
                                              (Outfile generation is skipped by default.)
  --mode=<mode>                             Treat files like a certain kind of project:
                                              relay: treat files like relay-compiler output
                                              project: treat files like a cohesive project (fragments are shared, names must be unique)
                                              file: treat each file like a stand-alone operation

                                            By default, this flag is set to:
                                              - "relay" if "__generated__" in the path
                                              - otherwise, "project"
  --header=<header>:<value>                 Add a header to the outgoing HTTP request
                                              (may be repeated)
  --add-typename                            Automatically adds the "__typename" field to your queries
  --quiet                                   Suppress status logging
  --verbose                                 Print debug output
  --help                                    Print this message
`)
} else {
  var commandName = argv._[0]

  if (commandName !== "sync") {
    console.log("Only `graphql-ruby-client sync` is supported")
  } else {
    var parsedHeaders: {[key: string]: string} = {}
    if (argv.header) {
      argv.header.forEach((h: string) => {
        var headerParts = h.split(":")
        parsedHeaders[headerParts[0]] = headerParts[1]
      })
    }
    var result = sync({
      path: argv.path,
      relayPersistedOutput: argv["relay-persisted-output"],
      apolloCodegenJsonOutput: argv["apollo-codegen-json-output"],
      apolloAndroidOperationOutput: argv["apollo-android-operation-output"],
      url: argv.url,
      client: argv.client,
      outfile: argv.outfile,
      outfileType: argv["outfile-type"],
      secret: argv.secret,
      mode: argv.mode,
      headers: parsedHeaders,
      addTypename: argv["add-typename"],
      quiet: argv.hasOwnProperty("quiet"),
      verbose: argv.hasOwnProperty("verbose"),
    })

    result.then(function() {
      process.exit(0)
    }).catch(function() {
      // The error is logged by the function
      process.exit(1)
    })
  }
}
