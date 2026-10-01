import ExcelJS from 'exceljs';
import { type DocumentSnapshot, type Firestore, Timestamp } from 'firebase-admin/firestore';

/**
 * The shop's data as a workbook people can open (PRD C9, N1: free export,
 * the data belongs to the shop) and as complete JSON (PDPA portability).
 * Tamil names stay text in Excel, so they render correctly there.
 */

const COLLECTIONS = ['customers', 'entries', 'items', 'stockMoves', 'dayClosings', 'reminders', 'members', 'auditLogs'];

type Row = Record<string, unknown>;

/** Timestamps become ISO strings; everything else is plain JSON. */
export function plain(value: unknown): unknown {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(plain);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value as Row).map(([k, v]) => [k, plain(v)]));
  }
  return value;
}

export interface ShopDump {
  shop: Row;
  exportedAt: string;
  collections: Record<string, Row[]>;
}

export async function dumpShop(db: Firestore, shopId: string, now: Date): Promise<ShopDump> {
  const shop = db.collection('shops').doc(shopId);
  const [shopDoc, ...snaps] = await Promise.all([shop.get(), ...COLLECTIONS.map((c) => shop.collection(c).get())]);
  const collections: Record<string, Row[]> = {};
  COLLECTIONS.forEach((name, i) => {
    collections[name] = snaps[i]!.docs.map((d: DocumentSnapshot) => ({ id: d.id, ...(plain(d.data()) as Row) }));
  });
  return { shop: { id: shopId, ...(plain(shopDoc.data() ?? {}) as Row) }, exportedAt: now.toISOString(), collections };
}

const rupees = (cents: unknown) => (typeof cents === 'number' ? cents / 100 : null);
const date = (iso: unknown) => (typeof iso === 'string' ? new Date(iso) : null);

/** One sheet each for customers, entries, stock and day closings. */
export async function workbook(dump: ShopDump): Promise<Buffer> {
  const wb = new ExcelJS.Workbook();
  wb.creator = 'Shop Companion';
  wb.created = new Date(dump.exportedAt);
  const names = new Map(dump.collections.customers!.map((c) => [c.id as string, c.name as string]));

  const sheet = (name: string, columns: [string, string, number][], rows: unknown[][]) => {
    const ws = wb.addWorksheet(name);
    ws.columns = columns.map(([header, key, width]) => ({ header, key, width }));
    ws.getRow(1).font = { bold: true };
    ws.views = [{ state: 'frozen', ySplit: 1 }];
    for (const r of rows) ws.addRow(r);
    return ws;
  };

  const customers = sheet(
    'Customers',
    [
      ['பெயர் / Name', 'name', 24],
      ['உறவு / Kinship', 'kinship', 12],
      ['தொலைபேசி / Phone', 'phone', 16],
      ['ஊர் / Village', 'village', 16],
      ['நிலுவை / Balance (Rs.)', 'balance', 16],
      ['பழைய நிலுவை முதல் / Unpaid since', 'since', 18],
    ],
    dump.collections.customers!
      .map((c) => [c.name, c.kinshipTerm ?? '', c.phone ?? '', c.village ?? '', rupees(c.balanceCents ?? 0), date(c.oldestUnpaidAt)])
      .sort((a, b) => (b[4] as number) - (a[4] as number)),
  );
  customers.getColumn('balance').numFmt = '#,##0.00';
  customers.getColumn('since').numFmt = 'yyyy-mm-dd';

  const entries = sheet(
    'Entries',
    [
      ['தேதி / Date', 'date', 18],
      ['வாடிக்கையாளர் / Customer', 'customer', 24],
      ['வகை / Type', 'type', 12],
      ['தொகை / Amount (Rs.)', 'amount', 14],
      ['முறை / Method', 'method', 10],
      ['பிரிவு / Category', 'category', 14],
      ['குறிப்பு / Note', 'note', 24],
      ['மூலம் / Source', 'source', 10],
      ['நீக்கப்பட்டது / Deleted', 'deleted', 12],
    ],
    dump.collections.entries!
      .map((e) => [
        date(e.txnDate ?? e.createdAt),
        typeof e.customerId === 'string' ? (names.get(e.customerId) ?? '') : '',
        e.type,
        rupees(e.amountCents),
        e.method ?? '',
        e.category ?? '',
        e.note ?? '',
        e.source ?? '',
        e.deletedAt ? 'yes' : '',
      ])
      .sort((a, b) => ((b[0] as Date | null)?.getTime() ?? 0) - ((a[0] as Date | null)?.getTime() ?? 0)),
  );
  entries.getColumn('date').numFmt = 'yyyy-mm-dd hh:mm';
  entries.getColumn('amount').numFmt = '#,##0.00';

  const stock = sheet(
    'Stock',
    [
      ['பொருள் / Item', 'name', 24],
      ['அளவு / Unit', 'unit', 10],
      ['எண்ணிக்கை / Qty', 'qty', 10],
      ['எச்சரிக்கை / Low at', 'low', 12],
      ['வாங்கும் விலை / Cost (Rs.)', 'cost', 14],
      ['விற்கும் விலை / Price (Rs.)', 'price', 14],
    ],
    dump.collections.items!.map((i) => [i.name, i.unit ?? '', i.qty, i.lowStockAt ?? '', rupees(i.costCents), rupees(i.priceCents)]),
  );
  stock.getColumn('cost').numFmt = '#,##0.00';
  stock.getColumn('price').numFmt = '#,##0.00';

  const days = sheet(
    'Close Day',
    [
      ['தேதி / Date', 'date', 12],
      ['விற்பனை / Sales', 'sales', 12],
      ['வந்த பணம் / Collected', 'collected', 12],
      ['செலவு / Spent', 'spent', 12],
      ['இருக்க வேண்டியது / Expected cash', 'expected', 14],
      ['எண்ணியது / Counted cash', 'counted', 14],
      ['வித்தியாசம் / Difference', 'diff', 12],
      ['இலாபம் (கணிப்பு) / Profit (estimate)', 'profit', 14],
    ],
    dump.collections.dayClosings!
      .map((d) => [
        d.id,
        rupees(d.salesCents),
        rupees(d.collectedCents),
        rupees(((d.expensesCents as number) ?? 0) + ((d.purchasesCents as number) ?? 0)),
        rupees(d.expectedCashCents),
        rupees(d.countedCashCents),
        rupees(d.differenceCents),
        rupees(d.profitEstimateCents),
      ])
      .sort((a, b) => String(b[0]).localeCompare(String(a[0]))),
  );
  for (const key of ['sales', 'collected', 'spent', 'expected', 'counted', 'diff', 'profit']) {
    days.getColumn(key).numFmt = '#,##0.00';
  }

  return Buffer.from(await wb.xlsx.writeBuffer());
}
