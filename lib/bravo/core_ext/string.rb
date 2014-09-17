# Added to avoid requiring ActiveSupport as dependency
#
class String
  # Stolen from activesupport/lib/active_support/inflector/methods.rb, line 48
  #
  def underscore
    word = to_s.dup
    word.gsub!(/::/, '/')
    word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
    word.tr!('-', '_')
    word.downcase!
    word
  end
end
