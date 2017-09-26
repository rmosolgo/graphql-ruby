import addGraphQLSubscriptions from '../addGraphQLSubscriptions';

describe('addGraphQLSubscriptions', () => {
  it('delegates to the subscriber', () => {
    const state = {};
    const subscriber = {
      subscribe(req, handler) {
        state[req] = handler;
        return `${req}/${handler}`;
      },
      unsubscribe(id) {
        const key = id.split('/')[0];
        delete state[key];
      },
    };

    const dummyNetworkInterface = addGraphQLSubscriptions({}, { subscriber });

    const id = dummyNetworkInterface.subscribe('abc', 'def');
    expect(id).toEqual('abc/def');
    expect(Object.keys(state).length).toEqual(1);
    expect(state.abc).toEqual('def');
    dummyNetworkInterface.unsubscribe(id);
    expect(Object.keys(state).length).toEqual(0);
  });
});
