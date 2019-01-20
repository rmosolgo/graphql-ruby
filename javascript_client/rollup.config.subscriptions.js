import resolve from "rollup-plugin-node-resolve";
import babel from "rollup-plugin-babel";
import commonjs from "rollup-plugin-commonjs";
import filesize from "rollup-plugin-filesize";

const env = process.env.NODE_ENV;
const pkg = require("./package.json");
const external = Object.keys(pkg.dependencies);

export default {
  input: "src/subscriptions/index.js",
  output: [
    {
      file: 'dist/subscriptions/graphql-ruby-client-subscriptions.umd.js',
      format: 'umd',
      name: 'graphql-ruby-client-subscriptions'
    },
    {
      file: 'dist/subscriptions/graphql-ruby-client-subscriptions.esm.js',
      format: 'esm',
      name: 'graphql-ruby-client-subscriptions'
    }
  ],
  external,
  plugins: [
    resolve(),
    babel({
      exclude: "node_modules/**"
    }),
    commonjs(),
    filesize()
  ]
};