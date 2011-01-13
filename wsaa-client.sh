#!/bin/bash
# FUNCTION: Bash script to get a TA from WSAA
# AUTHOR: Gerardo Fisanotti - AFIP/SDG-SI/DIITEC/DEARIN - 15-nov-2010
# Dependencies: curl, openssl >= 1.0, xmllint
#
# Modify following definitions according to your environment:
#
# URL=https://wsaahomo.afip.gov.ar/ws/services/LoginCms  # WSAA URL
# KEY=spec/fixtures/pkey      # file containing the private key in PEM format
# CRT=spec/fixtures/cert.crt      # file containing the X.509 certificate in PEM format
TAFN="TA.xml"    # file name of the output file
# modify next line if you need a proxy to get to the Internet or comment it out
# if you don't need a proxy
# export https_proxy="http://10.20.152.112:80"
#
# No further modifications should be needed below this line
#==============================================================================
function MakeTRA()
#
# Generate the XML containing the Access Ticket Request (TRA)
#
{
#  FROM=$(date -j -f "%a %b %d %T %Z %Y" "`date -v0H -v0M -v0S`" "+%s")
#  TO=$(date -j -f "%a %b %d %T %Z %Y" "`date -v23H -v59M -v59S`" "+%s")
	FROM=$(date "+%Y-%m-%dT00:00:00-03:00")
	TO=$(date "+%Y-%m-%dT23:59:59-03:00")
  ID=$(date "+%s")
  TRA=$(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<loginTicketRequest version="1.0">
  <header>
    <uniqueId>$ID</uniqueId>
    <generationTime>$FROM</generationTime>
    <expirationTime>$TO</expirationTime>
  </header>
  <service>wsfe</service>
</loginTicketRequest>
EOF
)
}
#------------------------------------------------------------------------------
function MakeCMS()
#
# Generate de CMS container (TRA + sign + certificate)
#
{
  CMS=$(
    echo "$TRA" |
    /usr/local/ssl/bin/openssl cms -sign -in /dev/stdin -signer $CRT -inkey $KEY -nodetach \
            -outform der |
    /usr/local/ssl/bin/openssl base64 -e
  )
}
#------------------------------------------------------------------------------
function MakeSOAPrequest()
#
# Generate the SOAP request XML
#
{
  REQUEST=$(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://wsaa.view.sua.dvadac.desein.afip.gov">
  <SOAP-ENV:Body>
    <ns1:loginCms>
      <ns1:in0>
$CMS
      </ns1:in0>
    </ns1:loginCms>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF
)
}
#------------------------------------------------------------------------------
function CallWSAA()
#
# Invoke WSAA sending SOAP request XML to LoginCMS method
#
{
  RESPONSE=$(
    echo "$REQUEST" |
    curl -k -H 'Content-Type: application/soap+xml; action=""' -d @- $URL
  )
		echo "$REQUEST"
}
#------------------------------------------------------------------------------
function ParseTA()
#
# Try to parse the results obtained from WSAA
#
{
  TOKEN=$(
    echo "$RESPONSE" |
    grep token |
    sed -e 's/&lt;token&gt;//' |
    sed -e 's/&lt;\/token&gt;//' |
    sed -e 's/ //g'
  )
  SIGN=$(
    echo "$RESPONSE" |
    grep sign |
    sed -e 's/&lt;sign&gt;//' |
    sed -e 's/&lt;\/sign&gt;//' |
    sed -e 's/ //g'
  )
# If we did not get TOKEN, then it was a SOAP Fault, show the error message
# and exit
#
if [ "$TOKEN" == "" ]
  then
    echo "ERROR: "
    echo "$(echo "$RESPONSE" | xmllint --format - | grep faultstring)"
    exit 1
fi
}
#------------------------------------------------------------------------------
function WriteTA()
#
# Write the token and sign to the output file
#
{
  cat <<EOF > $TAFN
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<loginTicketResponse version="1">
  <credentials>
    <token>$TOKEN</token>
    <sign>$SIGN</sign>
  </credentials>
</loginTicketResponse>
EOF
}

function WriteYAML()
{
	cat <<EOF > /tmp/bravo_$(date +"%d_%m_%Y").yml
token: '$TOKEN'
sign: '$SIGN'
EOF
}
#------------------------------------------------------------------------------
#
# MAIN program
#
# If we were invoked with a service name in arg #1, use it
#[ $# -eq 1 ] && SERVICE=$1
# otherwise, ask for it
#[ $# -eq 0 ] && read -p "Service name: " SERVICE

# Parse commandline arguments
while getopts 'k:u:c:' OPTION
do
    case $OPTION in
    c)    CRT=$OPTARG
        ;;
    k)    KEY=$OPTARG
        ;;
    u)    URL=$OPTARG
        ;;
    esac
done
shift $(($OPTIND - 1))
MakeTRA          # Generate TRA
MakeCMS          # Generate CMS (TRA + signature + certificate)
MakeSOAPrequest  # Generate the SOAP request XML
CallWSAA         # Invoke WSAA sending SOAP request
ParseTA          # Parse the WSAA SOAP response, extract Token and Sign
# WriteTA          # Write an abbreviated TA.xml with Token and Sign only
WriteYAML
echo "Access Ticket acquired, written to: $TAFN"  # Inform success and exit
echo $REQUEST
echo $TRA
