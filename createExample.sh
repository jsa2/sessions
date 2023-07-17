# Create cert for the app

openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout priv.key -out pub.crt -subj "/C=FI/ST=SDR/L=SANTACLAUSE/O=My Company/OU=My Division/CN=www.contoso.com"
