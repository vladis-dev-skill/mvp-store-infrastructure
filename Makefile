.PHONY: init up down restart status logs clean network-create network-remove health-check

# Infrastructure management commands

init: network-create
	@echo "🚀 Initializing MVP Store Infrastructure..."
	chmod +x configs/init-multiple-databases.sh
	docker-compose up -d
	@echo "⏳ Waiting for services to be ready..."
	sleep 10
	@echo "✅ Infrastructure initialized successfully!"
	@echo "📋 Next steps:"
	@echo "   1. Start backend: cd ../mvp-store-backend && make up"
	@echo "   2. Start payment service: cd ../mvp-store-payment-service && make up"
	@echo "   3. Access API Gateway at: http://localhost"

up:
	docker-compose up -d

down:
	docker-compose down

restart: down up

clean: down
	docker-compose down -v --remove-orphans
	docker volume prune -f

network-create:
	@echo "🌐 Creating shared network..."
	@docker network create mvp_store_network 2>/dev/null || echo "Network already exists"
	@echo "✅ Network ready"

network-remove:
	@echo "🗑️  Removing shared network..."
	@docker network rm mvp_store_network 2>/dev/null || echo "Network not found"
	@echo "✅ Network removed"