.PHONY: up down dev test chrome build-web

up:
	./scripts/local-up.sh

dev:
	./scripts/local-up.sh

down:
	docker compose down

test:
	docker compose exec app php artisan test

chrome:
	cd mobile && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api

build-web:
	cd mobile && flutter build web --dart-define=API_BASE_URL=http://localhost:8080/api
