# Gerado por setup-https-domain.sh — não editar à mão.
{
	email __ACME_EMAIL__
}

__DOMAIN__ {
	reverse_proxy nginx:80
}
