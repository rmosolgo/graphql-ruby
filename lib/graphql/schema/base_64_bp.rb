# frozen_string_literal: true

require 'base64'

# backport from ruby v2.5 to v2.2 that has no `padding` things
# @api private
module Base64Bp
  extend Base64

  module_function

  def urlsafe_encode64(bin, padding:)
    str = strict_encode64(bin)
    str.tr!("+/", "-_")
    str.delete!("=") unless padding
    str
  end

  def urlsafe_decode64(str)
    str = str.tr("-_", "+/")
    if !str.end_with?("=") && str.length % 4 != 0
      str = str.ljust((str.length + 3) & ~3, "=")
    end
    strict_decode64(str)
  end
end
