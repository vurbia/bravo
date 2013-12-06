module Bravo

  # This class handles authorization data
  #
  class AuthData

    class << self

      attr_accessor :environment, :todays_data_file_name

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

        unless File.exists?(todays_data_file_name)
          Bravo::Wsaa.login
        end

        YAML.load_file(todays_data_file_name).each do |k, v|
          Bravo.const_set(k.to_s.upcase, v) unless Bravo.const_defined?(k.to_s.upcase)
        end
      end

      # Returns the authorization hash, containing the Token, Signature and Cuit
      # @return [Hash]
      #
      def auth_hash
        fetch unless Bravo.constants.include?(:TOKEN) && Bravo.constants.include?(:SIGN)
        { 'Token' => Bravo::TOKEN, 'Sign'  => Bravo::SIGN, 'Cuit'  => Bravo.cuit }
      end

      # Returns the right wsaa url for the specific environment
      # @return [String]
      #
      def wsaa_url
        raise 'Environment not sent to either :test or :production' unless Bravo::URLS.keys.include? environment
        Bravo::URLS[environment][:wsaa]
      end

      # Returns the right wsfe url for the specific environment
      # @return [String]
      #
      def wsfe_url
        raise 'Environment not sent to either :test or :production' unless Bravo::URLS.keys.include? environment
        Bravo::URLS[environment][:wsfe]
      end

      # Creates the data file name for a cuit number and the current day
      # @return [String]
      #
      def todays_data_file_name
        @todays_data_file ||= "/tmp/bravo_#{ Bravo.cuit }_#{ Time.new.strftime('%Y_%m_%d') }.yml"
      end
    end
  end
end
