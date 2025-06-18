// src/app/api/sheet-data/route.ts
import { google } from 'googleapis';
import { NextResponse } from 'next/server'; // Importe NextResponse
import path from 'path';

const CREDENTIALS_PATH = path.join(process.cwd(), 'credentials.json');

// Para rotas GET no App Router, você usa a função GET
export async function GET(req: Request) {
  try {
    const auth = new google.auth.GoogleAuth({
      keyFile: CREDENTIALS_PATH,
      scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
    });

    const sheets = google.sheets({ version: 'v4', auth });

    const spreadsheetId = process.env.GOOGLE_SHEET_ID;
    const range = 'Sheet1!A:Z';

    if (!spreadsheetId) {
      // Use NextResponse para retornar JSON no App Router
      return NextResponse.json({ error: 'GOOGLE_SHEET_ID not defined in environment variables.' }, { status: 500 });
    }

    const response = await sheets.spreadsheets.values.get({
      spreadsheetId,
      range,
    });

    const rows = response.data.values;

    if (!rows || rows.length === 0) {
      return NextResponse.json({ data: [] }, { status: 200 });
    }

    const headers = rows[0];
    const data = rows.slice(1).map(row => {
      let obj: { [key: string]: any } = {};
      headers.forEach((header: string, index: number) => {
        obj[header] = row[index];
      });
      return obj;
    });

    return NextResponse.json({ data }, { status: 200 }); // Retorna os dados com status 200

  } catch (error: any) {
    console.error('Error accessing Google Sheet:', error);
    // Retorna o erro com status 500
    return NextResponse.json({ error: 'Failed to fetch data from Google Sheet.', details: error.message }, { status: 500 });
  }
}