module Bravo
  class Authorizer
    attr_reader :pkey, :cert

    def initialize
      @pkey = Bravo.pkey
      @cert = Bravo.cert
    end
  end
end