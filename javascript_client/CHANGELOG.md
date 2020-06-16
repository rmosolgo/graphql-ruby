# graphql-ruby-client

## 1.7.11 (15 June 2020)

- Ably: Improve channel state handling in case the initial subscription result contains errors #2993

## 1.7.10 (13 June 2020)

- Ably: Improve error handling and channel cleanup #2991

## 1.7.9 (15 May 2020)

- Ably: _completely_ unsubscribe when subscriptions are done #2944
- Ably: propagate errors from subscriptions #2944

## 1.7.8 (1 May 2020)

- `sync`: Add support for Apollo-Android's `OperationOutput.json` #2914

## 1.7.7 (15 Apr 2020)

- Ably handler: dispatch initial response #2866
- Ably handler: catch any error in initial HTTP call #2877

## 1.7.6 (3 Apr 2020)

- Fix ActionCableLink sending unsubcribe to ActionCable #2842

## 1.7.5 (4 Mar 2020)

- Add missing dependency declarations

## 1.7.4 (18 Feb 2020)

- Move all exports to top level
- Fix sync body handling: wait for all chunks, improve verbose output

## 1.7.3 (17 Feb 2020)

- Fix CLI for TypeScript

## 1.7.2 (17 Feb 2020)

- Convert outfile generators to TypeScript and include them in published package

## 1.7.1 (17 Feb 2020)

- Fix `bin` configuration in package.json

## 1.7.0 (17 Feb 2020)

- Rewrite in TypeScript

## 1.6.8 (18 Sept 2019)

- Properly send `Content-Type: application/json` when posting persisted operations

## 1.6.7 (18 Sept 2019)

- Add post data to `--verbose` output of `sync`

## 1.6.6 (6 Aug 2019)

- Add `--relay-persisted-output` for working with Relay Compiler's new `--persist-output` option #2415

## 1.6.5 (17 July 2019)

- Update dependencies #2335

## 1.6.4 (11 May 2019)

- Add `--verbose` option to `sync` #2075
- Support Relay 2.0.0 #2121
- ActionCableLink: support subscriber when there are errors but no data #2176

## 1.6.3 (11 Jan 2019)

- Fix `.unsubscribe()` for PusherLink #2042

## 1.6.2 (14 Dec 2018)

- Support identified Ably client #2003

## 1.6.1 (30 Nov 2018)

- Support `ably:` option for Relay subscriptions

## 1.6.0 (19 Nov 2018)

- Fix unused requires #1943
- Add `generateClient` function to generate code _without_ the HTTP call #1941

## 1.5.0 (27 October 2018)

- Fix `export` usage in PusherLink, use `require` and `module.exports` instead #1889
- Add `AblyLink` #1925

## 1.4.1 (19 Sept 2018)

- Add `connectionOptions` to ActionCableLink #1857

## 1.4.0 (12 Apr 2018)

- Add `PusherLink` for Apollo 2 Subscriptions on Pusher
- Add `OperationStoreLink` for Apollo 2 persisted queries

## 1.3.0 (30 Nov 2017)

- Support HTTPS, basic auth, query string and port in `sync` #1053
- Add Apollo 2 support for ActionCable subscriptions #1120
- Add `--outfile-type=json` for stored operation manifest #1142

## 1.2.0 (15 Nov 2017)

- Support Apollo batching middleware #1092

## 1.1.3 (11 Oct 2017)

- Fix Apollo + ActionCable unsubscribe function #1019

## 1.1.2 (9 Oct 2017)

- Add channel IDs to ActionCable subscriptions #1004

## 1.1.1 (21 Sept 2017)

- Add `--add-typename` option to `sync` #967

## 1.1.0 (18 Sept 2017)

- Add subscription clients for Apollo and Relay Modern

## 1.0.2 (22 Aug 2017)

- Remove debug output

## 1.0.1 (21 Aug 2017)

- Rename from `graphql-pro-js` to `graphql-ruby-client`

## 1.0.0 (31 Jul 2017)

- Add `sync` task
