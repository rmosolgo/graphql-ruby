const prepareIsolatedFiles = require('../prepareIsolatedFiles');

it('builds out single operations', () => {
  const filenames = [
    './src/__tests__/project/op_isolated_1.graphql',
    './src/__tests__/project/op_isolated_2.graphql',
  ];
  const ops = prepareIsolatedFiles(filenames, false);
  expect(ops).toMatchSnapshot();
});

describe('with --add-typename', () => {
  it('builds out single operations with __typename fields', () => {
    const filenames = [
      './src/__tests__/project/op_isolated_1.graphql',
      './src/__tests__/project/op_isolated_2.graphql',
    ];
    const ops = prepareIsolatedFiles(filenames, true);
    expect(ops).toMatchSnapshot();
  });
});
