# ekobelth

Aplicativo Flutter para gerenciar tratamentos e lembretes de medicamentos, com backend FastAPI e banco MySQL.

## Requisitos

- Flutter SDK
- Python 3.10+
- MySQL

## Banco de dados

O arquivo `database.sql` cria o banco `ekobelth`, o usuário local e a tabela `tratamentos`.

Antes de executar em um ambiente real, troque a senha placeholder:

```sql
CREATE USER IF NOT EXISTS 'ekobelth'@'localhost' IDENTIFIED BY 'troque-esta-senha';
```

Depois execute o script no MySQL:

```bash
mysql -u root -p < database.sql
```

## Backend

Configure as variáveis de ambiente do banco:

```bash
export EKOBELTH_DB_HOST=localhost
export EKOBELTH_DB_NAME=ekobelth
export EKOBELTH_DB_USER=ekobelth
export EKOBELTH_DB_PASSWORD=sua-senha
```

Instale as dependências usadas pelo backend e rode a API:

```bash
source .venv/bin/activate
pip install fastapi uvicorn pymysql
uvicorn main:app --reload
```

A API sobe por padrão em `http://127.0.0.1:8000`.

## Flutter

Instale as dependências e rode o app:

```bash
flutter pub get
flutter run
```

Para apontar o app para outra URL da API, use `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

No emulador Android, use `10.0.2.2` para acessar o backend da máquina local:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Testes

```bash
flutter test
flutter analyze
```
