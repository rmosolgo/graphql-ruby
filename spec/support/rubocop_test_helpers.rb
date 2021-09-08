# frozen_string_literal: true

module RubocopTestHelpers
  def run_rubocop_on(fixture_path, autocorrect: false)
    `bundle exec rubocop --debug #{autocorrect ? "--auto-correct" : ""} --config spec/fixtures/cop/.rubocop.yml #{fixture_path}`
  end

  def rubocop_errors(rubocop_result)
    rubocop_result =~ /(\d) offenses detected/
    $1.to_i
  end

  def assert_rubocop_autocorrects_all(fixture_path)
    autocorrect_target_path = fixture_path.sub(".rb", "_autocorrect.rb")
    FileUtils.cp(fixture_path, autocorrect_target_path)
    result = run_rubocop_on(autocorrect_target_path, autocorrect: true)
    result2 = run_rubocop_on(autocorrect_target_path)
    assert_equal 0, rubocop_errors(result2), "All errors were corrected"
  ensure
    FileUtils.rm(autocorrect_target_path)
  end
end
