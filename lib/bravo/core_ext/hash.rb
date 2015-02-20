# Methods stolen from ActiveSupport, to avoid requiring the gem as a dependency
class Hash
  # Alters the hash, converting it's keys to symbols
  # @return [Hash]
  #
  def symbolize_keys!
    keys.each do |key|
      self[(key.to_sym rescue key) || key] = delete(key)
    end
    self
  end unless method_defined?(:symbolize_keys!)

  # Returns a copy of the hash, with it's keys converted to symbols
  # @return [Hash]
  #
  def symbolize_keys
    dup.symbolize_keys!
  end unless method_defined?(:symbolize_keys)

  # Alters the hash, converting its keys to underscore strings
  # @return [Hash]
  #
  def underscore_keys!
    keys.each do |key|
      self[(key.underscore rescue key) || key] = delete(key)
    end
    self
  end unless method_defined?(:underscore_keys!)

  # Returns a copy of the hash, with it's keys converted to underscore strings
  # @return [Hash]
  def underscore_keys
    dup.underscore_keys!
  end unless method_defined?(:underscore_keys)
end
