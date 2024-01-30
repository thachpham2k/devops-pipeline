mkdir -p ssl
cd ssl
openssl genpkey -algorithm RSA -out gitlab.key
openssl req -new -key gitlab.key -out gitlab.csr
openssl x509 -req -days 365 -in gitlab.csr -signkey gitlab.key  -out gitlab.crt