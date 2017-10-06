/* eslint-disable global-require, import/no-dynamic-require */

const generateClient = require('../generateClient');
const fs = require('fs');

function withExampleClient(mapName, callback) {
  // Generate some code and write it to a file
  const exampleMap = { a: 'b', 'c-d': 'e-f' };
  const jsCode = generateClient('example-client', exampleMap);
  const filename = `src/${mapName}.js`;
  fs.writeFileSync(filename, jsCode);

  // Load the module and use it
  const exampleModule = require(`../../${mapName}`);
  callback(exampleModule);

  // Clean up the generated file
  fs.unlinkSync(filename);
}

it('generates a valid JavaScript module that maps names to operations', () => {
  withExampleClient('map1', (exampleClient) => {
    // It does the mapping
    expect(exampleClient.getPersistedQueryAlias('a')).toEqual('b');
    expect(exampleClient.getPersistedQueryAlias('c-d')).toEqual('e-f');
    // It returns a param
    expect(exampleClient.getOperationId('a')).toEqual('example-client/b');
  });
});

it('generates an Apollo middleware', () => {
  withExampleClient('map2', (exampleClient) => {
    let nextWasCalled = false;
    const next = () => {
      nextWasCalled = true;
    };
    const req = {
      operationName: 'a',
      query: 'x',
    };

    exampleClient.apolloMiddleware.applyMiddleware({ request: req }, next);

    expect(nextWasCalled).toEqual(true);
    expect(req.query).toBeUndefined();
    expect(req.operationId).toEqual('example-client/b');
  });
});
