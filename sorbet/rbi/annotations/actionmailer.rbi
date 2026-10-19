# typed: true

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

class ActionMailer::Base
  sig { params(headers: T.untyped, block: T.nilable(T.proc.params(arg0: ActionMailer::Collector).void)).returns(Mail::Message) }
  def mail(headers = nil, &block); end
end

module ActionMailer::TestHelper
  sig { params(block: T.proc.void).returns(T::Array[Mail::Message]) }
  def capture_emails(&block); end
end
