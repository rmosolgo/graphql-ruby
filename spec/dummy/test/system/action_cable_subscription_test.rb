# frozen_string_literal: true
require "application_system_test_case"

class ActionCableSubscriptionsTest < ApplicationSystemTestCase
  # This test covers a lot of ground!
  test "it handles subscriptions" do
    # Load the page and let the subscriptions happen
    visit "/"
    # make sure they connect successfully
    assert_selector "#updates-1-connected"
    assert_selector "#updates-2-connected"

    # Trigger a few updates, make sure we get a client update:
    click_on("Trigger 1")
    click_on("Trigger 1")
    click_on("Trigger 1")
    assert_selector "#updates-1-3", text: "3"
    # Make sure there aren't any unexpected elements:
    refute_selector "#updates-1-4"
    refute_selector "#updates-2-1"

    # Now, trigger updates to a different stream
    # and make sure the previous stream is not affected
    click_on("Trigger 2")
    click_on("Trigger 2")
    assert_selector "#updates-2-1", text: "1"
    assert_selector "#updates-2-2", text: "2"
    refute_selector "#updates-2-3"
    refute_selector "#updates-1-4"

    # Now unsubscribe one, it should not receive updates but the other should
    click_on("Unsubscribe 1")
    click_on("Trigger 1")
    # This should not have changed
    refute_selector "#updates-1-4"

    click_on("Trigger 2")
    assert_selector "#updates-2-3", text: "3"
    refute_selector "#updates-1-4"

    # wacky behavior to make sure the custom serializer is used:
    click_on("Trigger 2")
    assert_selector "#updates-2-400", text: "400"
  end


  test "it only re-runs queries once for subscriptions with matching fingerprints" do
    # Make 3 subscriptions to the same payload
    click_on("Subscribe with fingerprint 1")
    click_on("Subscribe with fingerprint 1")
    click_on("Subscribe with fingerprint 1")
    # And two to the next payload
    click_on("Subscribe with fingerprint 2")
    click_on("Subscribe with fingerprint 2")

    assert_selector "#fingerprint-updates-1-connected-1"
    assert_selector "#fingerprint-updates-1-connected-2"
    assert_selector "#fingerprint-updates-1-connected-3"
    assert_selector "#fingerprint-updates-2-connected-1"
    assert_selector "#fingerprint-updates-2-connected-2"

    # Now trigger. We expect a total of two updates:
    # - One is built & delivered to the first three subscribers
    # - Another is built & delivered to the next two
    click_on("Trigger with fingerprint 2")

    # These all share the first value:
    assert_selector "#fingerprint-updates-1-update-1-value-1"
    assert_selector "#fingerprint-updates-1-update-2-value-1"
    assert_selector "#fingerprint-updates-1-update-3-value-1"
    # and these share the second value:
    assert_selector "#fingerprint-updates-2-update-1-value-2"
    assert_selector "#fingerprint-updates-2-update-2-value-2"

    click_on("Unsubscribe with fingerprint 2")
    click_on("Trigger with fingerprint 1")

    # These get an update
    assert_selector "#fingerprint-updates-1-update-1-value-3"
    assert_selector "#fingerprint-updates-1-update-2-value-3"
    assert_selector "#fingerprint-updates-1-update-3-value-3"
    # But these are unsubscribed:
    refute_selector "#fingerprint-updates-2-update-1-value-4"
    refute_selector "#fingerprint-updates-2-update-2-value-4"
    click_on("Unsubscribe with fingerprint 1")
    # Make a new subscription and make sure it's updated:
    click_on("Subscribe with fingerprint 2")
    click_on("Trigger with fingerprint 2")
    assert_selector "#fingerprint-updates-2-update-3-value-4"
    # But this one was unsubscribed:
    refute_selector "#fingerprint-updates-1-update-1-value-5"
  end
end
