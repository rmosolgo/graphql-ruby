# frozen_string_literal: true

# Extracted and adapted from this talk from Ben Sheldon:
# `An ok compromise. Faster development by designing for the Rails Autoloader`
# Youtube video link: https://youtu.be/9-PWz9nbrT8?si=Lw7qsF2_VmBperId&t=1487

require_relative "./config/application"

autoloaded_constants = []

Rails.autoloaders.each do |loader|
  loader.on_load do |cpath, _value, _abspath|
    autoloaded_constants << [cpath, caller]
  end
end

Rails.application.initialize!

autoloaded_constants.each do |x|
  x[1] = Rails.backtrace_cleaner.clean(x[1]).first
end

allow_listed_constants = [
  'ActionText::ContentHelper',
  'ActionText::TagHelper',
]

puts
if !autoloaded_constants.reject! { _1.first.in?(allow_listed_constants) }.nil?
  puts
  puts "ERROR: Autoloaded constants were referenced during during boot."
  puts
  puts "These files/constants were autoloaded during the boot process, which will result in" \
       "inconsistent behavior and will slow down and may break development mode. " \
       "Remove references to these constants from code loaded at boot. "
  puts
  puts
  w = autoloaded_constants.map { _1.first.length }.max
  autoloaded_constants.each do |name, location|
    puts "`#{name.ljust(w)}` referenced by #{location}"
  end

  exit 1
else
  puts "SUCCESS! No autoloaded constants were found during the boot process."
  exit 0
end
