import GraphqlWs from 'graphql-ws'

class GraphqlWsClient implements GraphqlWs.Client {
  on(event: GraphqlWs.Event) {
    return () => {
      console.error('Subclass responsibility')
    }
  }

  subscribe(payload: GraphqlWs.SubscribePayload, sink: GraphqlWs.Sink) {
    return () => {
      console.error('Subclass responsibility')
    }
  }

  dispose() {
    console.error('Subclass responsibility')
  }
}

export default GraphqlWsClient
