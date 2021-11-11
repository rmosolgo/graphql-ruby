import GraphqlWs from 'graphql-ws'

class GraphqlWsClient implements GraphqlWs.Client {
  on(_event: GraphqlWs.Event) {
    console.error('Subclass responsibility')
    return () => {}
  }

  subscribe(_payload: GraphqlWs.SubscribePayload, _sink: GraphqlWs.Sink) {
    console.error('Subclass responsibility')
    return () => {}
  }

  dispose() {
    console.error('Subclass responsibility')
  }
}

export default GraphqlWsClient
