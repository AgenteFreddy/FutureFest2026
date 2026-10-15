const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// Serve os arquivos estáticos do site e aproveita os assets originais do app Flutter
app.use(express.static(path.join(__dirname, '../public')));
app.use('/assets', express.static(path.join(__dirname, '../public/assets')));
app.use('/assets', express.static(path.join(__dirname, '../../ekobelth/assets')));

let tratamentosDb = [
  {
    id: 1,
    paciente: "João",
    medicamento: "Amoxicilina",
    via: "Oral (Comprimido)",
    dose: "500mg",
    frequencia: "A cada 12 horas",
    inicio: "27/09/2026 19:30",
    fim: "30/09/2026 19:30",
    obs: "Administrar após a refeição"
  },
  {
    id: 2,
    paciente: "Maria Silva",
    medicamento: "Losartana",
    via: "Oral (Comprimido)",
    dose: "50mg",
    frequencia: "1 vez ao dia (24h)",
    inicio: "28/09/2026 08:00",
    fim: "28/12/2026 08:00",
    obs: "Em jejum pela manhã"
  },
  {
    id: 3,
    paciente: "Carlos Alberto",
    medicamento: "Omeprazol",
    via: "Oral (Comprimido)",
    dose: "20mg",
    frequencia: "1 vez ao dia (24h)",
    inicio: "28/09/2026 07:00",
    fim: "15/10/2026 07:00",
    obs: "30 min antes do café"
  }
];

let estoqueDb = [
  { id: 1, medicamento: "Amoxicilina", quantidade: "14 cápsulas", via: "Oral (Comprimido)", dataValidade: "15/12/2026", observacoes: "Caixa lacrada" },
  { id: 2, medicamento: "Losartana", quantidade: "30 comprimidos", via: "Oral (Comprimido)", dataValidade: "10/05/2027", observacoes: "Uso contínuo" },
  { id: 3, medicamento: "Omeprazol", quantidade: "28 cápsulas", via: "Oral (Comprimido)", dataValidade: "20/08/2027", observacoes: "Controle estrito" },
  { id: 4, medicamento: "Dipirona", quantidade: "2 frascos (20ml)", via: "Oral (Gotas)", dataValidade: "04/03/2028", observacoes: "Em caso de dor/febre" }
];

app.get('/api/tratamentos', (req, res) => {
  res.json(tratamentosDb);
});

app.post('/api/tratamentos', (req, res) => {
  const novo = { id: Date.now(), ...req.body };
  tratamentosDb.unshift(novo);
  res.status(201).json(novo);
});

app.delete('/api/tratamentos/:id', (req, res) => {
  const id = parseInt(req.params.id);
  tratamentosDb = tratamentosDb.filter(t => t.id !== id);
  res.json({ sucesso: true });
});

app.get('/api/estoque', (req, res) => {
  res.json(estoqueDb);
});

app.post('/api/estoque', (req, res) => {
  const novo = { id: Date.now(), ...req.body };
  estoqueDb.unshift(novo);
  res.status(201).json(novo);
});

app.delete('/api/estoque/:id', (req, res) => {
  const id = parseInt(req.params.id);
  estoqueDb = estoqueDb.filter(e => e.id !== id);
  res.json({ sucesso: true });
});

app.post('/api/eko', (req, res) => {
  const { pergunta } = req.body;
  const texto = (pergunta || '').toLowerCase();

  const joao = tratamentosDb.find(t => t.paciente.toLowerCase().includes('joão') || t.paciente.toLowerCase().includes('joao')) || tratamentosDb[0];

  let resposta = "Olá! Eu sou o Eko 💧, mascote e IA da Ekobélth! Você pode me perguntar sobre os horários de medicamentos do paciente João, estoque de remédios ou como editar informações.";

  if (texto.includes('joão') || texto.includes('joao') || texto.includes('medicamento') || texto.includes('amoxicilina') || texto.includes('horário') || texto.includes('horario') || texto.includes('remédio') || texto.includes('remedio')) {
    resposta = `📋 **Paciente ${joao.paciente}**\n• **Medicamento:** ${joao.medicamento} (${joao.frequencia})\n• **Dose:** ${joao.dose}\n• **Horário previsto:** ${joao.inicio.split(' ')[1] || '19:30'}\n• **Período:** ${joao.inicio} - ${joao.fim}\n• **Cuidadora responsável:** Iza`;
  } else if (texto.includes('estoque')) {
    const itens = estoqueDb.map(e => `• ${e.medicamento}: ${e.quantidade}`).join('\n');
    resposta = `📦 **Estoque Atual da ILPI:**\n${itens}\nTodos com controle ativo e dentro da validade!`;
  } else if (texto.includes('editar') || texto.includes('usuario') || texto.includes('usuário') || texto.includes('paciente')) {
    resposta = `✏️ Na tela **Editar Informações**, a cuidadora Iza pode ajustar medicamentos, doses, vias de administração, intervalos de horários e períodos de tratamento de forma rápida e segura.`;
  } else if (texto.includes('ilpi') || texto.includes('repouso') || texto.includes('problema') || texto.includes('manual') || texto.includes('brasil') || texto.includes('estatística')) {
    resposta = "📊 Segundo dados das ILPIs, de 70% a 80% das casas de repouso no Brasil ainda utilizam processos manuais como planilhas e blocos de notas. A Ekobélth substitui tudo isso por uma gestão digital inteligente!";
  }

  setTimeout(() => {
    res.json({ sucesso: true, resposta });
  }, 350);
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

const PORT = process.env.PORT || 3000;
if (process.env.NODE_ENV !== 'production') {
  app.listen(PORT, () => {
    console.log(`🌿 Ekobélth rodando em http://localhost:${PORT}`);
  });
}

module.exports = app;