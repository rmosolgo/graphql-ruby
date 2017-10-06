const registry = require('../registry');

describe('subscription registry', () => {
  it('adds and unsubscribes', () => {
    // A subscription is something that responds to `.unsubscribe`
    let wasUnsubscribed1 = false;
    const subscription1 = {
      unsubscribe() {
        wasUnsubscribed1 = true;
      },
    };
    let wasUnsubscribed2 = false;
    const subscription2 = {
      unsubscribe() {
        wasUnsubscribed2 = true;
      },
    };
    // Adding a subscription returns an ID for unsubscribing
    const id1 = registry.add(subscription1);
    const id2 = registry.add(subscription2);
    expect(typeof id1).toEqual('number');
    expect(typeof id2).toEqual('number');
    // Unsubscribing calls the `.unsubscribe `function
    registry.unsubscribe(id1);
    expect(wasUnsubscribed1).toEqual(true);
    expect(wasUnsubscribed2).toEqual(false);
    registry.unsubscribe(id2);
    expect(wasUnsubscribed1).toEqual(true);
    expect(wasUnsubscribed2).toEqual(true);
  });

  it('raises on unknown ids', () => {
    expect(() => {
      registry.unsubscribe('abc');
    }).toThrow('No subscription found for id: abc');
  });
});
