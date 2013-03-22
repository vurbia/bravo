module Bravo
  # This class handles authorization data
  #
  class AuthData

    class << self
      # Fetches WSAA Authorization Data to build the datafile for the day.
      # It requires the private key file and the certificate to exist and
      # to be configured as Bravo.pkey and Bravo.cert
      #
      def fetch
        unless File.exists?(Bravo.pkey)
          raise "Archivo de llave privada no encontrado en #{ Bravo.pkey }"
        end

        unless File.exists?(Bravo.cert)
          raise "Archivo certificado no encontrado en #{ Bravo.cert }"
        end

        todays_datafile = "/tmp/bravo_#{ Time.new.strftime('%d_%m_%Y') }.yml"
        opts = "-u https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
        opts += " -k #{ Bravo.pkey }"
        opts += " -c #{ Bravo.cert }"

        unless File.exists?(todays_datafile)
          Bravo::Wsaa.login
        end

        @data = YAML.load_file(todays_datafile).each do |k, v|
          Bravo.const_set(k.to_s.upcase, v) unless Bravo.const_defined?(k.to_s.upcase)
        end
      end
    end
  end
end
