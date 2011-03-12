class Hash
  def symbolize_keys!
    keys.each do |key|
      self[(key.to_sym rescue key) || key] = delete(key)
    end
    self
  end unless method_defined?(:symbolize_keys!)

  def symbolize_keys
    dup.symbolize_keys!
  end unless method_defined?(:symbolize_keys)

  def underscore_keys!
    keys.each do |key|
      self[(key.underscore rescue key) || key] = delete(key)
    end
    self
  end unless method_defined?(:underscore_keys!)

  def underscore_keys
    dup.underscore_keys!
  end unless method_defined?(:underscore_keys)
end
