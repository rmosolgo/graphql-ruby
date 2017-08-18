---
layout: guide
search: true
section: Subscriptions
title: Action Cable Implementation
desc: GraphQL subscriptions over ActionCable
index: 4
experimental: true
---

[ActionCable](http://guides.rubyonrails.org/action_cable_overview.html) is a great platform for delivering GraphQL subscriptions on Rails 5+. It handles message passing (via `broadcast`) and transport (via `transmit` over a websocket).

To get started, see examples in the API docs: {{ "GraphQL::Subscriptions::ActionCableSubscriptions" | api_doc }}.

A client is available [nowhere](#) (TODO).
