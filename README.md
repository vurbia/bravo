# Bravo ![Travis status](https://travis-ci.org/leanucci/bravo.png)

[~~Bravo~~](http://images.coveralia.com/audio/b/Bravo-Desierto_Sin_Amor-Frontal.jpg) Bravo permite la obtenci&oacute;n del [~~C.A.E~~](http://www.muevamueva.com/masmusica/latina/cae/images/fotos.5.gif) C.A.E. (C&oacute;digo de Autorizaci&oacute;n Electr&oacute;nico) por medio del Web Service de Facturaci&oacute;n Electr&oacute;nica provisto por AFIP.

## Requisitos

Para poder autorizar comprobantes mediante el WSFE, AFIP requiere de ciertos pasos detallados a continuación:

* Generar una clave privada para la aplicación.
* Generar un CSR (Certificate Signing Request) utilizando el número de CUIT que emitirá los comprobantes y la clave privada del paso anterior. Se deberá enviar a AFIP el CSR para obtener el Certificado X.509 que se utilizará en el proceso de autorización de comprobantes.
	* Para el entorno de Testing, se debe enviar el X.509 por email a _webservices@afip.gov.ar_.
	* Para el entorno de Producción, el trámite se hace a través del portal [AFIP](http://www.afip.gov.ar)
* El certificado X.509 y la clave privada son utilizados por Bravo para obtener el token y signature a incluir en el header de autenticacion en cada request que hagamaos a los servicios de AFIP.


### OpenSSL

Para cumplir con los requisitos de encriptación del [Web Service de Autenticación y Autorización](http://www.afip.gov.ar/ws/WSAA/README.txt) (WSAA), Bravo requiere [OpenSSL](http://openssl.org) en cualquier versión posterior a la 1.0.0a.

Como regla general, basta correr desde la línea de comandos

		openssl cms

Si el comando ```cms``` no está disponible, se debe actualizar OpenSSL.

### Certificados

AFIP exige para acceder a sus Web Services, la utilización del WSAA. Este servicio se encarga de la autorización y autenticación de cada request hecho al web service.

Una vez instalada la version correcta de OpenSSL, podemos generar la clave privada y el CSR.

* [Documentación WSAA](http://www.afip.gov.ar/ws/WSAA/Especificacion_Tecnica_WSAA_1.2.0.pdf)
* [Cómo generar el CSR](https://gist.github.com/leanucci/7520622)


## Uso

Luego de haber obtenido el certificado X.509, podemos comenzar a utilizar Bravo en el entorno para el cual sirve el certificado.

### Configuración

Bravo no asume valores por defecto, por lo cual hay que configurar de forma explícita todos los parámetros:

* ```pkey``` ruta a la clave privada
* ```cert``` ruta al certificado X.509
* ```cuit``` el número de CUIT para el que queremos emitir los comprobantes
* ```sale_point``` el punto de venta a utilizar (ante la duda consulte a su contador)
* ```default_concepto, default_documento y default_moneda``` estos valores pueden configurarse para no tener que pasarlos cada vez que emitamos un comprobante, ya que no suelen cambiar entre comprobantes emitidos por el mismo vendedor.
* ```own_iva_cond``` condicion propia ante el IVA
* ```openssl_bin``` path al ejecutable de OpenSSL

Ejemplo de configuración tomado del spec_helper de Bravo:

```ruby
require 'bravo'

Bravo.pkey              			 = 'spec/fixtures/certs/pkey'
Bravo.cert              			 = 'spec/fixtures/certs/cert.crt'
Bravo.cuit              			 = '20287740027'
Bravo.sale_point        			 = '0002'
Bravo.default_concepto  			 = 'Productos y Servicios'
Bravo.default_documento 			 = 'CUIT'
Bravo.default_moneda    			 = :peso
Bravo.own_iva_cond      			 = :responsable_inscripto
Bravo.verbose           			 = 'true'
Bravo.openssl_bin       			 = '/usr/local/Cellar/openssl/1.0.1e/bin/openssl'
Bravo::AuthData.environment			 = :test
```
### Emisión de comprobantes

Para emitir un comprobante, basta con:

* instanciar la clase `Bill`,
* pasarle los parámetros típicos del comprobante, como si lo llenásemos a mano,
* llamar el método `authorize`, para que el WSFE autorice el comprobante que acabamos de 'llenar':

#### Ejemplo

Luego de configurar Bravo, autorizamos una factura:

* Comprobante: Factura
* Tipo: 'B'
* A: consumidor final
* Total: $ 100 (si fuera una factura tipo A, este valor es el neto, y Bravo calcula el IVA correspondiente)

```ruby
# bloque de setup igual al de más arriba
factura = Bravo::Bill.new

factura.net          = 100.00				# el neto de la factura, total para Consumidor final
factura.aliciva_id   = 2					# define la alicuota de iva a utilizar, ver archivo constants.
factura.iva_cond     = :consumidor_final	# la condición ante el iva del comprador
factura.concepto     = 'Servicios'			# concepto de la factura
factura.invoice_type = :invoice				# el tipo de comprobante a emitir, en este caso factura.

bill.authorize

bill.response.cae							# contiene el cae para este comprobante.
```

## TODO list

* ~~rdoc~~
* mensajes de error m&aacute;s completos


## Agradecimientos

* Emilio Tagua por sus consejos y contribuciones.

Copyright (c) 2010 Leandro Marcucci  & Vurbia Technologies International Inc. See LICENSE.txt for further details.
