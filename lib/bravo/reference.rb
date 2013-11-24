module Bravo
  # Class in charge of issuing read requests on the api
  #
  class Reference
    # Fetches the number for the next bill to be issued
    # @return [Integer] the number for the next bill
    #
    def self.next_bill_number(cbte_type)
      set_client
      resp = @client.call(:fe_comp_ultimo_autorizado) do |soap|
        # soap.namespaces['xmlns'] = 'http://ar.gov.afip.dif.FEV1/'
        soap.message 'Auth' => Bravo::AuthData.auth_hash, 'PtoVta' => Bravo.sale_point, 'CbteTipo' => cbte_type
      end

      resp.to_hash[:fe_comp_ultimo_autorizado_response][:fe_comp_ultimo_autorizado_result][:cbte_nro].to_i + 1
    end

    # Fetches the possible document codes and names
    # @return [Hash]
    #
    def self.get_custom(operation)
      set_client
      resp = @client.call(operation) do |soap|
        soap.message 'Auth' => Bravo::AuthData.auth_hash
      end
      resp.to_hash
    end

    # Sets up the cliet to perform consults to the api
    #
    #
    def self.set_client
      Bravo::AuthData.fetch
      opts = { wsdl: Bravo::AuthData.wsfe_url }.merge! Bravo.logger_options
      @client = Savon.client(opts)
    end
  end
end
