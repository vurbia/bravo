require "rubygems"
require "bundler/setup"
require "bravo/version"
require "savon"
require "ruby-debug"

module Bravo
  autoload :Authorizer,   "bravo/authorizer"
  autoload :AuthData,     "bravo/auth_data"
  autoload :Biller,       "bravo/biller"

  extend self
  attr_reader :pkey, :cert
  def pkey=(relative_path)
    @pkey = File.read(relative_path)
  end

  def cert=(relative_path)
    @cert = File.read(relative_path)
  end

  def self.cuit
    "30711034389"
  end

  def auth_hash
    {"Token" => Bravo::TOKEN, "Sign"  => Bravo::SIGN, "Cuit"  => Bravo.cuit}
  end
end
