// src/components/ClientSheetLoader.tsx
"use client"; // ESSA LINHA É ESSENCIAL PARA TORNAR ESTE UM CLIENT COMPONENT

import dynamic from 'next/dynamic';

// Importa SheetDisplay aqui dentro do Client Component
const SheetDisplay = dynamic(() => import('./SheetDisplay'), { ssr: false });

export default function ClientSheetLoader() {
  return <SheetDisplay />;
}