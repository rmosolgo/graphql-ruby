# frozen_string_literal: true

module RubocopTestHelpers
  def run_rubocop_on(fixture_path, autocorrect: false)
    `bundle exec rubocop --debug #{autocorrect ? "--auto-correct" : ""} --config spec/fixtures/cop/.rubocop.yml #{fixture_path} 2>&1`
  end

  def rubocop_errors(rubocop_result)
    rubocop_result =~ /(\d) offenses detected/
    $1.to_i
  end

  def assert_rubocop_autocorrects_all(fixture_path)
    autocorrect_target_path = fixture_path.sub(".rb", "_autocorrect.rb")
    FileUtils.cp(fixture_path, autocorrect_target_path)
    run_rubocop_on(autocorrect_target_path, autocorrect: true)
    result2 = run_rubocop_on(autocorrect_target_path)
    assert_equal 0, rubocop_errors(result2), "All errors were corrected"
    expected_file = File.read(fixture_path.sub(".rb", "_corrected.rb"))
    assert_equal expected_file, File.read(autocorrect_target_path), "The autocorrected file has the expected contents"
  ensure
    FileUtils.rm(autocorrect_target_path)
  end
end
