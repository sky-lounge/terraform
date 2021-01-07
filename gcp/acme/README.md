# acme.tf

This terraform file uses an acme compliant provider, like Let's Encrypt, to provision certificates for the specified domain. This is designed to work only with domains where dns is delegated to Google Cloud DNS.  

## Inputs

The input variables are documented in the file. Please look there for details on how to use this.

## Outputs

The private key (`private_key_pem`), public key (`certificate_pem`), and signing key (`issuer_pem`) will be outputted. Please treat the private key as the sensitive information it is. If you need the full chain pem, you can concatenate the public key and signing key.

This **does not** do anything other than output the pem values to the console. It is your responsibility to handle these outputs. The intent is to use this terraform in a CI/CD system that would then place the certificates in the correct location for the given scenario.
