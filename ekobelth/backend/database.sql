CREATE DATABASE IF NOT EXISTS ekobelth
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'ekobelth'@'localhost' IDENTIFIED BY 'troque-esta-senha';
GRANT ALL PRIVILEGES ON ekobelth.* TO 'ekobelth'@'localhost';
FLUSH PRIVILEGES;

USE ekobelth;

-- Usuários (login). O admin@admin.com de testes é criado automaticamente pela API
-- ao iniciar (a senha é salva com hash, por isso não é inserida aqui).
CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  senha_hash VARCHAR(255) NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tratamentos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  paciente VARCHAR(255) NOT NULL,
  medicamento VARCHAR(255) NOT NULL,
  via VARCHAR(100) NOT NULL DEFAULT '',
  dose VARCHAR(100) NOT NULL DEFAULT '',
  frequencia VARCHAR(100) NOT NULL DEFAULT '',
  estoque VARCHAR(50) NOT NULL DEFAULT '',
  inicio VARCHAR(20) NOT NULL DEFAULT '',
  fim VARCHAR(20) NOT NULL DEFAULT '',
  obs TEXT NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario_id INT NULL,
  CONSTRAINT fk_tratamentos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS estoque (
  id INT AUTO_INCREMENT PRIMARY KEY,
  medicamento VARCHAR(255) NOT NULL,
  quantidade VARCHAR(100) NOT NULL DEFAULT '',
  via VARCHAR(100) NOT NULL DEFAULT '',
  data_validade VARCHAR(50) NOT NULL DEFAULT '',
  observacoes TEXT NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario_id INT NULL,
  CONSTRAINT fk_estoque_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);
