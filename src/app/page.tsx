// src/app/page.tsx
import ClientSheetLoader from '../components/ClientSheetLoader'; // Importa o novo componente

export default function HomePage() {
  return (
    <main>
      <h1>Dados da Planilha Google</h1>
      <ClientSheetLoader /> {/* Usa o componente wrapper */}
    </main>
  );
}