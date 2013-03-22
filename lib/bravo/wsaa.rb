# -*- encoding: utf-8 -*-
module Bravo
  class Wsaa
    def self.login
      tra   = build_tra
      cms   = build_cms(tra)
      req   = build_request(cms)
      auth  = call_wsaa(req)
      write_yaml(auth)
    end

    protected
    def self.build_tra
      from = Time.now.strftime("%FT%T%:z")
      to   = (Time.now + (24*60*60)).strftime("%FT%T%:z")
      id   = Time.now.strftime("%s")
      tra  = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<loginTicketRequest version="1.0">
  <header>
    <uniqueId>#{ id }</uniqueId>
    <generationTime>#{ from }</generationTime>
    <expirationTime>#{ to }</expirationTime>
  </header>
  <service>wsfe</service>
</loginTicketRequest>
EOF
      return tra
    end

    def self.build_cms(tra)
      cms = `echo '#{ tra }' |
        #{ Bravo.openssl_bin } cms -sign -in /dev/stdin -signer #{ Bravo.cert } -inkey #{ Bravo.pkey } -nodetach \
                -outform der |
        #{ Bravo.openssl_bin } base64 -e`
      return cms
    end

    def self.build_request(cms)
      request = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://wsaa.view.sua.dvadac.desein.afip.gov">
  <SOAP-ENV:Body>
    <ns1:loginCms>
      <ns1:in0>
#{ cms }
      </ns1:in0>
    </ns1:loginCms>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
XML
      return request
    end

    def self.call_wsaa(req)
      response = `echo '#{ req }' |
        curl -k -H 'Content-Type: application/soap+xml; action=""' -d @- #{ Bravo.wsaa_url }`

      response = CGI::unescapeHTML(response)
      token = response.scan(/\<token\>(.+)\<\/token\>/).first.first
      sign  = response.scan(/\<sign\>(.+)\<\/sign\>/).first.first
      return [token, sign]
    end

    def self.write_yaml(certs)
      yml = <<-YML
token: #{certs[0]}
sign: #{certs[1]}
YML
    `echo '#{ yml }' > /tmp/bravo_#{ Time.new.strftime('%d_%m_%Y') }.yml`
    end

  end
end