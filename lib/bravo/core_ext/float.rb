class Float
  def round_with_precision(precision = nil)
    precision.nil? ? round : (self * (10 ** precision)).round / (10 ** precision).to_f
  end
  def round_up_with_precision(precision = nil)
    precision.nil? ? round : ((self * (10 ** precision)).round + 1) / (10 ** precision).to_f
  end
end