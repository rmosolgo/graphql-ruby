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
end
