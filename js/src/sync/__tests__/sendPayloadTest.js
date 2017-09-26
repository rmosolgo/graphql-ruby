jest.dontMock('nock');
const nock = require('nock');
const sendPayload = require('../sendPayload');

describe('Posting GraphQL to OperationStore Endpoint', () => {
  it('Posts to the specified URL', () => {
    const mock = nock('http://example.com')
      .post('/stored_operations/sync')
      .reply(200, { ok: 'ok' });

    return sendPayload('payload', { url: 'http://example.com/stored_operations/sync' }).then(() => {
      expect(mock.isDone()).toEqual(true);
    });
  });

  it('Returns the response JSON to the promise', () => {
    nock('http://example.com')
      .post('/stored_operations/sync')
      .reply(200, { result: 'ok' });

    return sendPayload('payload', { url: 'http://example.com/stored_operations/sync' }).then((response) => {
      expect(response).toEqual('{"result":"ok"}');
    });
  });

  it('Adds an hmac-sha256 header if key is present', () => {
    const payload = { payload: [1, 2, 3] };
    const key = '2f26b770ded2a04279bc4bf824ca54ac';
    /* eslint-disable max-len */
    // ruby -ropenssl -e 'puts OpenSSL::HMAC.hexdigest("SHA256", "2f26b770ded2a04279bc4bf824ca54ac", "{\"payload\":[1,2,3]}")'
    // f6eab31abc2fa446dbfd2e9c10a778aaffd4d0c1d62dd9513d6f7ea60557987c
    /* eslint-enable max-len */
    const signature = 'f6eab31abc2fa446dbfd2e9c10a778aaffd4d0c1d62dd9513d6f7ea60557987c';
    const mock = nock('http://example.com', {
      reqheaders: {
        authorization: `GraphQL::Pro Abc ${signature}`,
      },
    })
      .post('/stored_operations/sync')
      .reply(200, { result: 'ok' });

    const opts = { secret: key, client: 'Abc', url: 'http://example.com/stored_operations/sync' };
    return sendPayload(payload, opts).then((response) => {
      expect(response).toEqual('{"result":"ok"}');
      expect(mock.isDone()).toEqual(true);
    });
  });
});
