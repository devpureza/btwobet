# Gerado por setup-https-domain.sh — não editar à mão.
{
	email {$ACME_EMAIL}
}

{$DOMAIN} {
	reverse_proxy nginx:80
}
