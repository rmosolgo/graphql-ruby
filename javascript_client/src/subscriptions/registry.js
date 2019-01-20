// State management for subscriptions.
// Used to add subscriptions to an Apollo network intrface.
var registry = {
  // Apollo expects unique ids to reference each subscription,
  // here's a simple incrementing ID generator which starts at 1
  // (so it's always truthy)
  _id: 1,

  // Map{id => <#unsubscribe()>}
  // for unsubscribing when Apollo asks us to
  _subscriptions: {},

  add(subscription) {
    var id = this._id++
    this._subscriptions[id] = subscription
    return id
  },

  unsubscribe(id) {
    var subscription = this._subscriptions[id]
    if (!subscription) {
      throw new Error("No subscription found for id: " + id)
    }
    subscription.unsubscribe()
    delete this._subscriptions[id]
  },
}

export default registry
