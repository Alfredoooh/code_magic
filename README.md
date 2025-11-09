# 📦 Data Server - Sistema Infinito de APIs

## 🏗️ Estrutura de Pastas do Repositório

```
data-server/
├── public/
│   ├── news/
│   │   ├── news1.json
│   │   ├── news2.json
│   │   ├── news3.json
│   │   ├── news4.json
│   │   └── ... (sem limite, infinito!)
│   ├── books/
│   │   ├── book1.json
│   │   ├── book2.json
│   │   ├── book3.json
│   │   └── ... (sem limite, infinito!)
│   ├── advertisements/
│   │   ├── ad1.json
│   │   ├── ad2.json
│   │   └── ... (sem limite, infinito!)
│   ├── avatars/
│   │   ├── avatar1.json
│   │   ├── avatar2.json
│   │   └── ... (sem limite, infinito!)
│   └── index.html
├── server.js
├── package.json
├── README.md
└── .gitignore
```

## ♾️ Sistema Infinito

O sistema busca automaticamente os arquivos JSON numerados até encontrar 3 erros consecutivos (404), então volta para o início. Você pode adicionar quantos arquivos quiser!

---

## 📄 Arquivos de Configuração

### `package.json`

```json
{
  "name": "data-server",
  "version": "1.0.0",
  "description": "Static JSON API server with infinite file support",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "engines": {
    "node": ">=18.x"
  }
}
```

### `server.js`

```javascript
const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Servir arquivos estáticos
app.use(express.static('public'));

// Rota raiz
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Endpoint para listar arquivos disponíveis
app.get('/api/list/:type', (req, res) => {
  const type = req.params.type; // news, books, ads, avatars
  const dirPath = path.join(__dirname, 'public', type);
  
  if (!fs.existsSync(dirPath)) {
    return res.status(404).json({ error: 'Directory not found' });
  }
  
  const files = fs.readdirSync(dirPath)
    .filter(file => file.endsWith('.json'))
    .sort((a, b) => {
      const numA = parseInt(a.match(/\d+/)?.[0] || '0');
      const numB = parseInt(b.match(/\d+/)?.[0] || '0');
      return numA - numB;
    });
  
  res.json({ 
    type,
    totalFiles: files.length,
    files 
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Data Server rodando em http://localhost:${PORT}`);
  console.log(`♾️ Sistema infinito ativado`);
  console.log(`📰 News: http://localhost:${PORT}/news/news1.json, news2.json, ...`);
  console.log(`📚 Books: http://localhost:${PORT}/books/book1.json, book2.json, ...`);
  console.log(`📢 Ads: http://localhost:${PORT}/advertisements/ad1.json, ad2.json, ...`);
  console.log(`👤 Avatars: http://localhost:${PORT}/avatars/avatar1.json, avatar2.json, ...`);
});
```

### `public/index.html`

```html
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Data Server API - Sistema Infinito</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 900px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.1em;
        }
        
        .infinite-badge {
            display: inline-block;
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 8px 20px;
            border-radius: 25px;
            font-size: 0.9em;
            font-weight: bold;
            margin-bottom: 20px;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.8; }
        }
        
        .endpoints {
            margin-top: 30px;
        }
        
        .endpoint {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 8px;
            transition: transform 0.2s;
        }
        
        .endpoint:hover {
            transform: translateX(5px);
        }
        
        .endpoint-title {
            font-weight: bold;
            color: #667eea;
            margin-bottom: 5px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .endpoint-url {
            font-family: 'Courier New', monospace;
            color: #555;
            word-break: break-all;
            font-size: 0.95em;
        }
        
        .endpoint-pattern {
            background: #e9ecef;
            padding: 8px 12px;
            border-radius: 6px;
            margin-top: 8px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            color: #495057;
        }
        
        .status {
            display: inline-block;
            background: #10b981;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            margin-top: 20px;
        }
        
        .info-box {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 8px;
            padding: 15px;
            margin-top: 20px;
        }
        
        .info-box strong {
            color: #856404;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>♾️ Data Server API</h1>
        <p class="subtitle">Sistema infinito de dados JSON</p>
        
        <div class="infinite-badge">♾️ INFINITO - Adicione quantos arquivos quiser!</div>
        
        <span class="status">✓ Online</span>
        
        <div class="endpoints">
            <h2>📋 Padrões de Endpoints</h2>
            
            <div class="endpoint">
                <div class="endpoint-title">
                    📰 Notícias
                </div>
                <div class="endpoint-pattern">
                    /news/news1.json<br>
                    /news/news2.json<br>
                    /news/news3.json<br>
                    ... (infinito)
                </div>
            </div>
            
            <div class="endpoint">
                <div class="endpoint-title">
                    📚 Livros
                </div>
                <div class="endpoint-pattern">
                    /books/book1.json<br>
                    /books/book2.json<br>
                    /books/book3.json<br>
                    ... (infinito)
                </div>
            </div>
            
            <div class="endpoint">
                <div class="endpoint-title">
                    📢 Anúncios
                </div>
                <div class="endpoint-pattern">
                    /advertisements/ad1.json<br>
                    /advertisements/ad2.json<br>
                    /advertisements/ad3.json<br>
                    ... (infinito)
                </div>
            </div>
            
            <div class="endpoint">
                <div class="endpoint-title">
                    👤 Avatares
                </div>
                <div class="endpoint-pattern">
                    /avatars/avatar1.json<br>
                    /avatars/avatar2.json<br>
                    /avatars/avatar3.json<br>
                    ... (infinito)
                </div>
            </div>
            
            <div class="endpoint">
                <div class="endpoint-title">
                    💚 Health Check
                </div>
                <div class="endpoint-url">/health</div>
            </div>
            
            <div class="endpoint">
                <div class="endpoint-title">
                    📋 Listar Arquivos
                </div>
                <div class="endpoint-pattern">
                    /api/list/news<br>
                    /api/list/books<br>
                    /api/list/advertisements<br>
                    /api/list/avatars
                </div>
            </div>
        </div>
        
        <div class="info-box">
            <strong>ℹ️ Como funciona:</strong><br>
            O app busca arquivos sequencialmente (news1, news2, news3...) até encontrar 3 erros consecutivos (404), então volta para o início. Você pode adicionar quantos arquivos JSON quiser sem limite!
        </div>
    </div>
</body>
</html>
```

---

## 📊 Estrutura dos Arquivos JSON

### News (news1.json, news2.json, ...)

```json
{
  "articles": [
    {
      "id": "news_1_001",
      "title": "...",
      "description": "...",
      "content": "...",
      "source": "...",
      "author": "...",
      "imageUrl": "...",
      "category": "...",
      "tags": [...],
      "publishedAt": "2025-11-09T10:30:00Z",
      "url": "..."
    }
  ],
  "metadata": {
    "version": "1.0.0",
    "fileNumber": 1,
    "totalArticles": 5,
    "lastUpdated": "2025-11-09T00:00:00Z"
  }
}
```

### Books (book1.json, book2.json, ...)

```json
{
  "books": [
    {
      "id": "book_1_001",
      "title": "...",
      "author": "...",
      "description": "...",
      "category": "...",
      "coverImageURL": "...",
      "digitalPrice": 15000,
      "physicalPrice": 25000,
      "digitalFormat": "PDF, EPUB",
      "hasPhysicalVersion": true,
      "pages": 336,
      "publisher": "...",
      "isbn": "...",
      "language": "Português"
    }
  ],
  "metadata": {
    "version": "1.0.0",
    "fileNumber": 1,
    "totalBooks": 8,
    "lastUpdated": "2025-11-09T00:00:00Z"
  }
}
```

### Advertisements (ad1.json, ad2.json, ...)

```json
{
  "advertisements": [
    {
      "id": "ad_1_001",
      "title": "...",
      "description": "...",
      "imageUrl": "...",
      "actionUrl": "...",
      "actionText": "Ver Mais",
      "category": "...",
      "backgroundColor": "#1877F2",
      "priority": 1,
      "isActive": true,
      "startDate": "2025-01-01T00:00:00Z",
      "endDate": "2025-12-31T23:59:59Z"
    }
  ],
  "metadata": {
    "version": "1.0.0",
    "fileNumber": 1,
    "totalAds": 5,
    "lastUpdated": "2025-11-09T00:00:00Z"
  }
}
```

### Avatars (avatar1.json, avatar2.json, ...)

```json
{
  "avatars": [
    {
      "id": "avatar_1_001",
      "name": "Avatar Abstrato Azul",
      "imageUrl": "https://i.pravatar.cc/300?img=1",
      "category": "abstract",
      "color": "#1877F2"
    }
  ],
  "metadata": {
    "version": "1.0.0",
    "fileNumber": 1,
    "totalAvatars": 16,
    "lastUpdated": "2025-11-09T00:00:00Z"
  }
}
```

---

## 🚀 Deploy no Render

### Passo 1: Preparar Repositório

```bash
git init
git add .
git commit -m "Initial commit - Infinite Data Server"
git branch -M main
git remote add origin https://github.com/seu-usuario/data-server.git
git push -u origin main
```

### Passo 2: Deploy

1. Acesse [render.com](https://render.com)
2. **New +** → **Web Service**
3. Conecte seu repositório
4. Configure:
   - **Name**: `data-server`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free
5. **Create Web Service**

### Passo 3: Testar

Sua URL será algo como:
```
https://data-server-xxxx.onrender.com
```

Teste os endpoints:
```
https://data-server-xxxx.onrender.com/news/news1.json
https://data-server-xxxx.onrender.com/books/book1.json
https://data-server-xxxx.onrender.com/advertisements/ad1.json
https://data-server-xxxx.onrender.com/avatars/avatar1.json
```

---

## 🔄 Como Adicionar Mais Arquivos

### Adicionar Notícias

1. Crie `news100.json` (ou qualquer número)
2. Commit e push
3. Render fará redeploy automático
4. App buscará automaticamente

### Adicionar Livros

1. Crie `book50.json`
2. Push para GitHub
3. Pronto!

**Não há limite!** O sistema continua buscando até encontrar 3 erros consecutivos.

---

## 💡 Dicas de Performance

- Mantenha cada arquivo com 5-10 itens
- Use imagens otimizadas
- IDs únicos em cada item
- Atualize metadata com timestamp

---

## 📈 Monitoramento

Acesse no Render:
- **Logs** → Ver requisições em tempo real
- **Metrics** → Uso de CPU e memória
- **Environment** → Variáveis e configurações

---

## ✅ Checklist Final

- [ ] Criar repositório GitHub
- [ ] Adicionar arquivos JSON numerados
- [ ] Configurar `server.js` e `package.json`
- [ ] Push para GitHub
- [ ] Deploy no Render
- [ ] Testar todos os endpoints
- [ ] Atualizar `_apiBaseUrl` no app
- [ ] Testar app completo
- [ ] Adicionar mais arquivos conforme necessário

---

## 🎯 Resumo do Sistema Infinito

✅ **News**: news1.json, news2.json, ... ♾️  
✅ **Books**: book1.json, book2.json, ... ♾️  
✅ **Ads**: ad1.json, ad2.json, ... ♾️  
✅ **Avatars**: avatar1.json, avatar2.json, ... ♾️  

**Sem limite! Adicione quantos quiser!**