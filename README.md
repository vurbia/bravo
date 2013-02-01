# Bravo ![Travis status](https://travis-ci.org/leanucci/bravo.png)

> la gema de facturaci&oacute;n electr&oacute;nica argentina

[~~Bravo~~](http://images.coveralia.com/audio/b/Bravo-Desierto_Sin_Amor-Frontal.jpg) Bravo permite la obtenci&oacute;n del [~~C.A.E~~](http://www.muevamueva.com/masmusica/latina/cae/images/fotos.5.gif) C.A.E. (C&oacute;digo de Autorizaci&oacute;n Electr&oacute;nico) por medio del Web Service de Facturaci&oacute;n Electr&oacute;nica provisto por AFIP.

## Instalaci&oacute;n

	gem install bravo

o

	gem 'bravo'


en tu `Gemfile`


## Configuraci&oacute;n

Los servicios de AFIP requieren la utilizaci&oacute;n del Web Service de Autorizaci&oacute;n y Autenticaci&oacute;n [wsaa readme](http://www.afip.gov.ar/ws/WSAA/README.txt)

Luego de cumplidos los pasos indicados en el readme, basta con configurar Bravo con la ruta a los archivos:

	Bravo.pkey = "spec/fixtures/pkey"
 	Bravo.cert = "spec/fixtures/cert.crt"


y exportar la variable CUIT con el n&uacute;mero de cuit usado para obtener los certificados:

	export CUIT=_numerodecuit_

Bravo acepta m&aacute;s opciones, para m&aacute;s detalles ver el archivo [spec/spec_helper.rb](https://github.com/vurbia/Bravo/blob/master/spec/spec_helper.rb)

## Uso

El uso de la gema se centra en el metodo `authorize`. Este m&eacute;todo invoca `FECAESolicitar` y devuelve el resultado, que de ser exitoso incluye el CAE y su fecha de vencimento (ver [spec/bravo/bill_spec.rb:87](https://github.com/vurbia/Bravo/blob/master/spec/bravo/bill_spec.rb#L87)


## TODO list

* rdoc
* mensajes de error m&aacute;s completos


## Agradecimientos

* Emilio Tagua por sus consejos y contribuciones.

Copyright (c) 2010 Leandro Marcucci  & Vurbia Technologies International Inc. See LICENSE.txt for further details.
