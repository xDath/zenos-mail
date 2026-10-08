# Zenos Mail

Dashboard pribadi untuk mengirim dan menerima email dari beberapa domain melalui Resend. Daftar domain diambil langsung dari Resend, sehingga domain baru tidak perlu ditambahkan ke kode atau environment Vercel.

## Menjalankan lokal

```bash
npm ci
cp .env.example .env.local
npm run dev
```

Isi `.env.local` dengan kredensial sendiri. Jangan commit file tersebut.

| Variable | Kegunaan |
| --- | --- |
| `RESEND_API_KEY` | API key Resend dengan akses penuh untuk domain, kirim, dan inbox |
| `DASHBOARD_PASSWORD` | Password dashboard yang kuat |
| `JWT_SECRET` | String acak panjang untuk menandatangani sesi |
| `RESEND_WEBHOOK_SECRET` | Signing secret webhook `email.received` dari Resend |
| `SENDER_EMAIL` | Alamat pengirim awal, harus pada domain yang terverifikasi |
| `SENDER_NAME` | Nama pengirim awal |
| `REPLY_TO` | Reply-to awal, opsional |
| `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` | Notifikasi inbox via Telegram, opsional |

Set variabel yang sama di Vercel untuk Production. Jika `DASHBOARD_PASSWORD` atau `JWT_SECRET` kosong, login sengaja dinonaktifkan. Saat menambah webhook di Resend, pilih hanya event `email.received` dan URL `https://<project>.vercel.app/api/webhook/resend`; salin signing secret ke `RESEND_WEBHOOK_SECRET`.

## Menambah domain

1. Buka **Settings**, masukkan domain (misalnya `alte.codes`), lalu klik **Add Domain**.
2. Salin record DNS yang ditampilkan ke penyedia DNS domain. Klik **Verify DNS** dan refresh status sampai `verified`.
3. Bila ingin menerima email di domain itu, klik **Enable Inbox**, pasang record MX penerimaan yang muncul, lalu pastikan webhook Resend aktif. Mengubah MX utama dapat memindahkan seluruh email masuk dari penyedia lama; cek pengaturan domain dahulu.
4. Buka **Send**, pilih domain terverifikasi dan ketik nama alamat sebelum `@`. Alamat terakhir disimpan di browser sebagai pilihan awal.

Domain dan statusnya disimpan di Resend. Nama pengirim, reply-to, dan riwayat kirim hanya tersimpan di browser yang dipakai. Inbox menampilkan email masuk dari Resend dan dapat difilter menurut domain penerima.

## Verifikasi sebelum rilis

```bash
npm run build
npm audit
```

Uji login, daftar domain, kirim email dari setiap domain terverifikasi, inbox, dan webhook di lingkungan yang terhubung ke akun Resend sebenarnya.
