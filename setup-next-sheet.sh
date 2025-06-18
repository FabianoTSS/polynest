#!/bin/bash

# --- Variáveis de Configuração ---
# Substitua pelo ID da sua planilha Google
GOOGLE_SHEET_ID="SEU_ID_DA_PLANILHA_AQUI"
# Caminho para o seu arquivo de credenciais da GCP
CREDENTIALS_FILE="credentials.json"
# --- Fim das Variáveis de Configuração ---

echo "Iniciando a configuração do projeto Next.js com Google Sheets e MUI..."

# 1. Criação das pastas
echo "Criando estrutura de pastas..."
mkdir -p src/api src/components src/types src/styles

# 2. Criação do .env.local
echo "Criando .env.local e adicionando GOOGLE_SHEET_ID..."
cat <<EOF > .env.local
GOOGLE_SHEET_ID=${GOOGLE_SHEET_ID}
EOF

# 3. Atualização do .gitignore
echo "Atualizando .gitignore..."
if ! grep -q "credentials.json" .gitignore; then
  echo -e "\n# Google Cloud Credentials" >> .gitignore
  echo "credentials.json" >> .gitignore
fi

if ! grep -q ".env.local" .gitignore; then
  echo -e "\n# Environment variables" >> .gitignore
  echo ".env.local" >> .gitignore
  echo ".env.production.local" >> .gitignore
  echo ".env.development.local" >> .gitignore
  echo ".env.test.local" >> .gitignore
fi


# 4. Criação de src/api/sheet-data.ts
echo "Criando src/api/sheet-data.ts..."
cat <<EOF > src/api/sheet-data.ts
import { google } from 'googleapis';
import type { NextApiRequest, NextApiResponse } from 'next';
import path from 'path';

// Certifique-se de que o arquivo de credenciais está no .gitignore
// E que ele está disponível para o ambiente de produção
const CREDENTIALS_PATH = path.join(process.cwd(), '${CREDENTIALS_FILE}');

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const auth = new google.auth.GoogleAuth({
      keyFile: CREDENTIALS_PATH,
      scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
    });

    const sheets = google.sheets({ version: 'v4', auth });

    const spreadsheetId = process.env.GOOGLE_SHEET_ID;
    const range = 'Sheet1!A:Z';

    if (!spreadsheetId) {
      return res.status(500).json({ error: 'GOOGLE_SHEET_ID not defined in environment variables.' });
    }

    const response = await sheets.spreadsheets.values.get({
      spreadsheetId,
      range,
    });

    const rows = response.data.values;

    if (!rows || rows.length === 0) {
      return res.status(200).json({ data: [] });
    }

    const headers = rows[0];
    const data = rows.slice(1).map(row => {
      let obj: { [key: string]: any } = {};
      headers.forEach((header: string, index: number) => {
        obj[header] = row[index];
      });
      return obj;
    });

    res.status(200).json({ data });

  } catch (error: any) {
    console.error('Error accessing Google Sheet:', error);
    res.status(500).json({ error: 'Failed to fetch data from Google Sheet.', details: error.message });
  }
}
EOF

# 5. Criação de src/components/SheetDisplay.tsx
echo "Criando src/components/SheetDisplay.tsx..."
cat <<EOF > src/components/SheetDisplay.tsx
// src/components/SheetDisplay.tsx
import { useEffect, useState } from 'react';
import { Box, Typography, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow } from '@mui/material';

interface SheetDataItem {
  [key: string]: string;
}

export default function SheetDisplay() {
  const [data, setData] = useState<SheetDataItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const res = await fetch('/api/sheet-data');
        if (!res.ok) {
          throw new Error(\`HTTP error! status: \${res.status}\`);
        }
        const result = await res.json();
        if (result.error) {
          throw new Error(result.error);
        }
        setData(result.data);
      } catch (e: any) {
        setError(e.message);
        console.error("Failed to fetch sheet data:", e);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return <Typography>Carregando dados...</Typography>;
  }

  if (error) {
    return <Typography color="error">Erro ao carregar dados: {error}</Typography>;
  }

  if (data.length === 0) {
    return <Typography>Nenhum dado encontrado.</Typography>;
  }

  const headers = Object.keys(data[0]);

  return (
    <Box sx={{ p: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Dados da Planilha Google
      </Typography>
      <TableContainer component={Paper}>
        <Table sx={{ minWidth: 650 }} aria-label="simple table">
          <TableHead>
            <TableRow>
              {headers.map((header) => (
                <TableCell key={header}>
                  <Typography variant="subtitle1" fontWeight="bold">
                    {header}
                  </Typography>
                </TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {data.map((row, index) => (
              <TableRow key={index}>
                {headers.map((header) => (
                  <TableCell key={header}>
                    {row[header]}
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
}
EOF

# 6. Atualização de src/pages/index.tsx para usar o componente
echo "Atualizando src/pages/index.tsx para incluir SheetDisplay..."
cat <<EOF > src/pages/index.tsx
// src/pages/index.tsx
import dynamic from 'next/dynamic';

// Importa o componente SheetDisplay dinamicamente para garantir que ele só seja renderizado no cliente
// Isso evita problemas de SSR com algumas dependências do MUI ou do Google API que podem esperar ambiente de navegador
const SheetDisplay = dynamic(() => import('../components/SheetDisplay'), { ssr: false });

export default function HomePage() {
  return (
    <div>
      <SheetDisplay />
    </div>
  );
}
EOF

# 7. Criação de src/types/sheet.d.ts
echo "Criando src/types/sheet.d.ts..."
cat <<EOF > src/types/sheet.d.ts
// src/types/sheet.d.ts
declare interface SheetDataItem {
  [key: string]: string | number | boolean | null | undefined;
  // Adicione aqui as tipagens específicas para suas colunas, se souber
  // Por exemplo:
  // id: string;
  // nome: string;
  // idade: number;
}
EOF

echo "Configuração concluída!"
echo ""
echo "PRÓXIMOS PASSOS IMPORTANTES:"
echo "1. Baixe seu arquivo de credenciais da GCP e salve-o como '${CREDENTIALS_FILE}' na raiz do seu projeto."
echo "2. Substitua 'SEU_ID_DA_PLANILHA_AQUI' no arquivo .env.local pelo ID real da sua planilha Google."
echo "3. Compartilhe sua planilha Google com o email da conta de serviço (encontrado no seu arquivo '${CREDENTIALS_FILE}')."
echo "4. Instale as dependências: npm install googleapis dotenv @mui/material @emotion/react @emotion/styled"
echo "5. Inicie seu projeto Next.js: npm run dev"