#!/usr/bin/env bash
# Fast core test suite - excludes async IO, ActiveRecord, known-failing tests
# ~2200 tests in ~45s vs full suite
set -e
cd "$(dirname "$0")"
exec bundle exec ruby -Ispec -Ilib -Igraphql-c_parser/lib test_fast.rb "$@"
