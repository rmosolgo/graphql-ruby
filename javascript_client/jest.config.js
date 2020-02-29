module.exports = {
  roots: [
    "<rootDir>/src"
  ],
  verbose: true,
  testMatch: [
    "**/__tests__/**/*.ts",
  ],
  transform: {
    "^.+\\.ts$": "ts-jest"
  },
}
