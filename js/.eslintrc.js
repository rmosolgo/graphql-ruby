module.exports = {
  "extends": "airbnb-base",
  "plugins": [
    "jest"
  ],
  "env": {
    "jest/globals": true
  },
  "rules": {
    "no-plusplus": "off",
    "max-len": ["error", 120]
  }
};
