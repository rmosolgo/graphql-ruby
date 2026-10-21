# typed: true

# Core methods missing from Sorbet's bundled RBIs
class Fiber
  # Ruby 3.0+
  sig { returns(T.untyped) }
  def self.scheduler; end
end
