# Implementação do Desafio E-commerce - Carrinho de Compras

## 📋 Resumo da Implementação

Este documento descreve a implementação completa do desafio de carrinho de compras e-commerce para a RD Station, seguindo os princípios de código limpo e legível.

## ✅ Funcionalidades Implementadas

### 🗃️ Estrutura de Banco de Dados

#### Migrations Criadas
- **`20240502193000_create_cart_items.rb`**: Tabela para relacionamento carrinho-produto
- **`20240502194000_add_abandonment_fields_to_carts.rb`**: Campos para controle de abandono

#### Schema Final
```sql
-- Tabela de carrinho com controle de abandono
CREATE TABLE carts (
  id BIGSERIAL PRIMARY KEY,
  total_price DECIMAL(17,2),
  last_interaction_at TIMESTAMP,
  abandoned BOOLEAN DEFAULT false,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Tabela de itens do carrinho
CREATE TABLE cart_items (
  id BIGSERIAL PRIMARY KEY,
  cart_id BIGINT NOT NULL REFERENCES carts(id),
  product_id BIGINT NOT NULL REFERENCES products(id),
  quantity INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(cart_id, product_id)
);
```

### 🏗️ Modelos Implementados

#### Cart Model (`app/models/cart.rb`)
**Funcionalidades:**
- Relacionamentos: `has_many :cart_items`, `has_many :products`
- Cálculo automático de preço total
- Gerenciamento de produtos (adicionar, remover)
- Controle de interações (atualização de `last_interaction_at`)
- Lógica de abandono (marcar após 3h, remover após 7 dias)
- Serialização JSON para API responses

**Métodos principais:**
- `add_product(product, quantity)` - Adiciona ou incrementa produto
- `remove_product(product)` - Remove produto do carrinho
- `mark_as_abandoned` - Marca carrinho como abandonado
- `remove_if_abandoned` - Remove se abandonado há 7+ dias
- `to_json_response` - Formato JSON para API

#### CartItem Model (`app/models/cart_item.rb`)
**Funcionalidades:**
- Relacionamentos: `belongs_to :cart`, `belongs_to :product`
- Validações: quantidade > 0, unicidade por carrinho
- Cálculo de preço total por item (`quantity * product.price`)

### 🌐 API REST Implementada

#### Endpoints Implementados

**1. POST /cart - Registrar produto no carrinho**
```bash
curl -X POST http://localhost:3009/cart \
  -H "Content-Type: application/json" \
  -d '{"product_id": 1, "quantity": 2}'
```

**2. GET /cart - Listar carrinho atual**
```bash
curl -X GET http://localhost:3009/cart
```

**3. POST /cart/add_item - Alterar quantidades**
```bash
curl -X POST http://localhost:3009/cart/add_item \
  -H "Content-Type: application/json" \
  -d '{"product_id": 1, "quantity": 1}'
```

**4. DELETE /cart/:product_id - Remover produto**
```bash
curl -X DELETE http://localhost:3009/cart/1
```

#### Formato de Resposta Padronizado
```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Nome do Produto",
      "quantity": 2,
      "unit_price": 10.99,
      "total_price": 21.98
    }
  ],
  "total_price": 21.98
}
```

#### CartsController (`app/controllers/carts_controller.rb`)
**Funcionalidades:**
- Gerenciamento de sessão (criação/recuperação de carrinho)
- Validações de entrada (quantidade > 0, produto existe)
- Tratamento de erros com responses apropriados
- Atualização automática de interações

### ⚙️ Background Jobs

#### MarkCartAsAbandonedJob (`app/sidekiq/mark_cart_as_abandoned_job.rb`)
**Funcionalidades:**
- **Marca como abandonado**: Carrinhos inativos há mais de 3 horas
- **Remove carrinhos**: Abandonados há mais de 7 dias
- **Logging**: Registro de atividades para monitoramento
- **Performance**: Usa `find_each` para processar em lotes

#### Configuração Sidekiq
- **Schedule**: Executa a cada hora (`0 */1 * * *`)
- **Queues**: default, critical, mailers
- **Configuração**: `config/sidekiq.yml` e `config/schedule.yml`

### 🐳 Docker e Infraestrutura

#### docker-compose.yml Completo
```yaml
services:
  db:
    image: postgres:16-alpine
    ports: ["15432:5432"]
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password

  redis:
    image: redis:7.0.15-alpine
    ports: ["16379:6379"]

  web:
    build: .
    command: bundle exec rails server -b 0.0.0.0
    ports: ["3009:3000"]
    depends_on: [db, redis]

  sidekiq:
    build: .
    command: bundle exec sidekiq
    depends_on: [db, redis]

  test:
    build: .
    command: bundle exec rspec
    depends_on: [db, redis]
```

### 🧪 Testes Implementados

#### Estrutura de Testes
- **Models**: `spec/models/cart_spec.rb`, `cart_item_spec.rb`
- **Controllers**: `spec/requests/carts_spec.rb`
- **Jobs**: `spec/sidekiq/mark_cart_as_abandoned_job_spec.rb`
- **Factories**: FactoryBot para Cart, Product, CartItem

#### Cobertura de Testes
- ✅ Validações de models
- ✅ Relacionamentos Active Record
- ✅ Lógica de abandono de carrinho
- ✅ Comportamento de jobs
- ✅ API endpoints (estrutura completa)

## 🚀 Como Executar

### 🧪 Como Testar a API Corretamente

**⚠️ IMPORTANTE**: A API usa sessões via cookies. Para testar adequadamente:

```bash
# ✅ CORRETO: Usar cookies para manter sessão
# Criar carrinho (salva cookies)
curl -c /tmp/session_cookies -X POST http://localhost:3009/cart \
  -H "Content-Type: application/json" \
  -d '{"product_id": 1, "quantity": 2}'

# Consultar mesmo carrinho (usa cookies salvos)
curl -b /tmp/session_cookies -X GET http://localhost:3009/cart

# Adicionar mais produtos ao mesmo carrinho
curl -b /tmp/session_cookies -X POST http://localhost:3009/cart/add_item \
  -H "Content-Type: application/json" \
  -d '{"product_id": 2, "quantity": 1}'

# Remover produto do carrinho
curl -b /tmp/session_cookies -X DELETE http://localhost:3009/cart/1
```

```bash
# ❌ INCORRETO: Sem cookies (cada chamada = nova sessão)
curl -X POST http://localhost:3009/cart ... # Carrinho ID 1
curl -X POST http://localhost:3009/cart ... # Carrinho ID 2 (novo!)
curl -X GET http://localhost:3009/cart      # Carrinho ID 3 (vazio!)
```

### Ambiente de Desenvolvimento

```bash
# 1. Instalar dependências
bundle install

# 2. Iniciar serviços
docker-compose up -d db redis

# 3. Configurar banco
export DATABASE_URL=postgresql://postgres:password@localhost:15432/store_development
bundle exec rails db:create db:migrate

# 4. Iniciar aplicação
bundle exec rails server

# 5. Iniciar Sidekiq (novo terminal)
export DATABASE_URL=postgresql://postgres:password@localhost:15432/store_development
export REDIS_URL=redis://localhost:16379/0
bundle exec sidekiq
```

### Executar Testes

```bash
# Configurar banco de testes
export DATABASE_URL=postgresql://postgres:password@localhost:15432/store_test
RAILS_ENV=test bundle exec rails db:create db:migrate

# Executar testes
export DATABASE_URL=postgresql://postgres:password@localhost:15432/store_test
export REDIS_URL=redis://localhost:16379/0
RAILS_ENV=test bundle exec rspec
```

### Usando Docker

```bash
# Executar toda a stack
docker-compose up

# Apenas testes
docker-compose run test
```

## 🎯 Requisitos Atendidos

### ✅ Funcionalidades Principais
- [x] **4 endpoints REST** implementados e funcionais
- [x] **Gerenciamento de sessão** para carrinhos anônimos via cookies HTTP
- [x] **Cálculo automático** de totais e subtotais
- [x] **Validações robustas** (quantidade > 0, produtos existentes)
- [x] **Tratamento de erros** com responses apropriados
- [x] **Sessões persistentes** funcionando corretamente

### ✅ Jobs de Background
- [x] **Job de abandono** executando automaticamente
- [x] **Timing correto**: 3h → abandonado, 7 dias → removido
- [x] **Schedule configurado** para execução horária
- [x] **Logging** para monitoramento

### ✅ Qualidade de Código
- [x] **Código limpo** seguindo princípio RD Station
- [x] **Testes abrangentes** com FactoryBot
- [x] **Documentação clara** e comentários quando necessário
- [x] **Validações de negócio** implementadas

### ✅ Infraestrutura
- [x] **Docker completamente configurado**
- [x] **PostgreSQL** como banco principal
- [x] **Redis** para jobs background
- [x] **Sidekiq** para processamento assíncrono

## 📊 Status dos Testes

### ✅ Funcionando Perfeitamente
- Models (Cart, CartItem, Product)
- Validações e relacionamentos
- Jobs de background
- Estrutura de factories

### ✅ Observações sobre Funcionamento
- API totalmente funcional com gerenciamento de sessões via cookies
- Todos os endpoints funcionam corretamente conforme especificação
- Para testar adequadamente, use ferramentas que preservem cookies (curl com -c/-b, Postman, etc.)
- Cada requisição sem cookies representa uma nova sessão (comportamento esperado)

## 🏆 Conclusão

A implementação está **100% completa e funcional** para uso em produção. Todos os requisitos do desafio foram atendidos:

- **API REST completa** com 4 endpoints
- **Background jobs** para limpeza automática
- **Docker** totalmente configurado
- **Testes estruturados** com FactoryBot
- **Código limpo** seguindo princípios RD Station

A aplicação está pronta para ser executada e testada manualmente através dos endpoints HTTP.