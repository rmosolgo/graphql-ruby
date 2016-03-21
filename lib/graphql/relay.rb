require 'base64'
require 'graphql'
# MONKEY PATCHES 😬
require 'graphql/relay/monkey_patches/base_type'

require 'graphql/relay/define'
require 'graphql/relay/global_node_identification'
require 'graphql/relay/page_info'
require 'graphql/relay/edge'
require 'graphql/relay/base_connection'
require 'graphql/relay/array_connection'
require 'graphql/relay/relation_connection'
require 'graphql/relay/global_id_field'
require 'graphql/relay/mutation'
require 'graphql/relay/connection_field'

# Accept Relay-specific definitions
GraphQL::BaseType.accepts_definitions(
  connection: GraphQL::Relay::Define::AssignConnection,
  global_id_field: GraphQL::Relay::Define::AssignGlobalIdField,
)
