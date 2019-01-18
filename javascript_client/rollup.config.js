import resolve from "rollup-plugin-node-resolve";
import babel from "rollup-plugin-babel";
import commonjs from "rollup-plugin-commonjs";
import filesize from "rollup-plugin-filesize";

const env = process.env.NODE_ENV;
const pkg = require("./package.json");
const external = Object.keys(pkg.dependencies);

export default {
  input: "src/index.js",
  output: {
    file: {
      es: pkg.module,
      cjs: pkg.main
    }[env],
    format: env
  },
  external: external,
  plugins: [
    resolve(),
    babel({
      exclude: "node_modules/**"
    }),
    commonjs(),
    filesize()
  ]
};