module Bravo
  class AuthData

    class << self
      def fetch
        todays_datafile = "/tmp/bravo_#{Time.new.strftime('%d_%m_%Y')}.yml"
        opts = "-u https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
        keys_root = "/Users/leanucci/Xephstratus/afip/claves/"
        opts += " -k #{Bravo.pkey}"
        opts += " -c #{Bravo.cert}"

        unless File.exists?(todays_datafile)
          %x(#{ENV["BUNDLE_PATH"]}/gems/bravo-#{Bravo::VERSION}/wsaa-client.sh #{opts})
        end

        @data = YAML.load_file(todays_datafile).each do |k, v|
          Bravo.const_set(k.to_s.upcase, v) unless Bravo.const_defined?(k.to_s.upcase)
        end
      end
    end
  end
end