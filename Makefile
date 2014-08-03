.PHONY: doc certs

venv:
	virtualenv venv
	./venv/bin/pip install -r requirements.txt

doc:
	cd doc && make html

pep8:
	pep8 --ignore E501 carml/*.py carml/command/*.py

certs:
	@echo 'Acquiring certificates from: https://www.digicert.com/digicert-root-certificates.html'
	@echo 'DigiCert High Assurance EV Root CA'
	curl --silent --ciphers ECDH+AES256 https://www.digicert.com/CACerts/DigiCertHighAssuranceEVRootCA.crt | openssl x509 -inform der -outform pem -out carml/keys/digicert-root-ca.pem

	## NOTE to self, it seems that after (presumably)
	## heartbleed-related changes, the intermediate certificate is
	## different -- this is the pre-April-10th-or-so one
	#@echo 'DigiCert High Assurance CA-3'
	#curl --silent --ciphers ECDH+AES256 https://www.digicert.com/CACerts/DigiCertHighAssuranceCA-3.crt | openssl x509 -inform der -outform pem -out carml/keys/digicert.pem
	@echo 'DigiCert SHA2 High Assurance Server CA'
	curl --silent --ciphers ECDH+AES256 https://www.digicert.com/CACerts/DigiCertSHA2HighAssuranceServerCA.crt | openssl x509 -inform der -outform pem -out carml/keys/digicert-sha2.pem

	@echo 'torproject.org (and was for check.torproject.org too when i looked)'
	echo "" | openssl s_client -showcerts -connect torproject.org:443 | openssl x509 -outform pem -out carml/keys/torproject.pem


fake-tor-certs: create_ca_and_sign_request.py create_key_and_csr.py
	-rm server-privkey.pem
	python create_key_and_csr.py foo.csr
	python create_ca_and_sign_request.py foo.csr
	-rm foo.csr
	mv server-privkey.pem server.bundle containers/web/

test-services: carml-dns carml-web

carml-dns: containers/dns/Dockerfile #dockerbase-wheezy-image
	@echo "Creating a Docker.io container for DNS service"
	docker build -rm -q -t carml-tester-dns ./containers/dns

carml-web: fake-tor-certs containers/web/Dockerfile #dockerbase-wheezy-image
	@echo "Creating a Docker.io container for Web service"
	docker build -rm -q -t carml-tester-web ./containers/web