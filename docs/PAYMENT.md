# Setup Pembayaran (Xendit)

Aplikasi memakai Xendit untuk **koleksi pembayaran** (QRIS & checkout session) dan
**payout** (transfer ke rekening ketua komunitas).

---

## 1. Akun & API Key

1. Daftar/verifikasi akun [xendit.co](https://www.xendit.co)
2. Dashboard → Settings → API keys:
   - **Development key** untuk sandbox (`xnd_development_...`)
   - **Production key** saat go-live (`xnd_production_...`)
3. Pasang ke secrets (jangan pernah di-commit):

```bash
firebase functions:secrets:set XENDIT_SECRET_KEY
```

## 2. Webhook Token

Buat string acak (mis. `openssl rand -hex 24`), lalu pasang dua sisi:

```bash
firebase functions:secrets:set XENDIT_WEBHOOK_TOKEN
```

Dan daftarkan di dashboard Xendit (Settings → Webhooks) sebagai callback
verification token.

## 3. Daftarkan Webhook URL

Di dashboard Xendit (region Indonesia), isi 3 URL ini:

```
https://asia-southeast1-<PROJECT_ID>.cloudfunctions.net/xenditPaymentSessionWebhook
https://asia-southeast1-<PROJECT_ID>.cloudfunctions.net/xenditQrisWebhook
https://asia-southeast1-<PROJECT_ID>.cloudfunctions.net/xenditDisbursementWebhook
```

Region `asia-southeast1` mengikuti `setGlobalOptions` di `functions/src/index.ts`.

## 4. Alur Pembayaran

1. Pemain menyelesaikan registrasi → wizard step **QRIS PAYMENT**
2. Turnamen **fee 0** → otomatis **FREE ENTRY** (tanpa QRIS, langsung aktif)
3. Client memanggil `createXenditQrisPayment` → server membuat QRIS dynamic
   (`/qr_codes`, amount dari `feePolicy`) → QR tampil di layar
4. Auto-check tiap 10 detik + webhook → `paymentStatus: paid` →
   registrasi `active` + tiket QR muncul di detail turnamen
5. QRIS kedaluwarsa → buat ulang (server menolak session lama)

## 5. Payout ke Ketua Komunitas

1. Ketua membuka komunitas dashboard → request withdrawal (nominal + rekening)
2. Super admin → **PAYOUT QUEUE** → **PROCESS** → `createXenditDisbursement`
   (mapping bank: BCA/BNI/BRI/Mandiri/Permata/CIMB/Danamon/Maybank/Panin/OCBC/BSI)
3. Status berjalan: `processing` → webhook → `completed` / `failed`
4. **SYNC** tersedia untuk refresh manual status dari Xendit

## 6. Sandbox → Production

| Saat sandbox | Saat go-live |
|---|---|
| `XENDIT_SECRET_KEY` = `xnd_development_...` | ganti ke `xnd_production_...` |
| QRIS "sandbox wallet" (Xendit dashboard simulate) | scan QRIS asli |
| Webhook: pakai URL + token yang sama | pastikan URL aktif kembali |

Fee referensi (Indonesia): QRIS 0.70% + processing fee; payout 1% (min Rp2.500) +
processing fee — cek [halaman biaya Xendit](https://www.xendit.co/id/biaya/) untuk angka terkini.
