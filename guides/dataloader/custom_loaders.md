---
layout: guide
doc_stub: false
search: true
section: Dataloader
title: Custom loaders
desc: Writing a custom batch loader for GraphQL-Ruby
index: 3
---

To write a custom batch loader, you have to consider a few points:

- Loader keys: these inputs tell the dataloader how work can be batched
- Fetch parameters: these inputs are accumulated into batches, and dispatched all at once
- Executing the service call: How to take inputs and group them into an external call
- Handling the results: mapping the results of the external call back to the fetch parameters
- Dataloader key: A shortcut method for using your new dataloader

## Loader Keys

## Fetch Parameters

## Executing the Service Call

## Handling the Results
