# Gerado por setup-https-domain.sh — não editar à mão.
{
	email __ACME_EMAIL__
}

__DOMAIN__, www.__DOMAIN__ {
	reverse_proxy nginx:80
}

# IP direto (sem TLS válido no IP; use o domínio para HTTPS)
http://:80 {
	reverse_proxy nginx:80
}
