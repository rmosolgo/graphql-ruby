# frozen_string_literal: true
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  teardown do
    # Adapted from https://medium.com/@coorasse/catch-javascript-errors-in-your-system-tests-89c2fe6773b1
    errors = page.driver.browser.manage.logs.get(:browser)
    if errors.present?
      errors.each do |error|
        assert_nil "#{error.level}: #{error.message}"
      end
    end
  end
end
