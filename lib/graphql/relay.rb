require 'base64'
# MONKEY PATCHES 😬
require 'graphql/definition_helpers/defined_by_config/definition_config'
require_relative './object_type.rb'

require 'graphql/relay/node'
require 'graphql/relay/page_info'
require 'graphql/relay/edge'
require 'graphql/relay/base_connection'
require 'graphql/relay/array_connection'
require 'graphql/relay/relation_connection'
require 'graphql/relay/global_id_field'
require 'graphql/relay/mutation'
