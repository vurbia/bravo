require 'yaml'
module Bravo
  class AuthData

    def read
      get_authdata
    end

    def get_authdata
      # setear endpoint, key, cert, cuit, filename ✔
      # crear filename del dia ✔

      todays_datafile = "/tmp/bravo_#{Time.new.strftime('%d_%m_%Y')}.yml"
      %x("./wsaa-client.sh") unless File.exists?(todays_datafile)

      @data = YAML.load_file(todays_datafile).each do |k, v|
        Bravo.const_set(k.to_s.upcase, v)
      end
    end
  end
end