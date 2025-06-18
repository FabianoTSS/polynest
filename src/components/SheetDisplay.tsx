"use client"; // Esta linha é crucial

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
          throw new Error(`HTTP error! status: ${res.status}`);
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