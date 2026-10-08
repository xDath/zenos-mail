# Zenos Mail

Dashboard pribadi untuk mengirim dan menerima email dari beberapa domain melalui Resend. Daftar domain diambil langsung dari Resend, sehingga domain baru tidak perlu ditambahkan ke kode atau environment Vercel.

## Aplikasi Android

Client Flutter berada di [`mobile/`](mobile/). Interface awal mencakup inbox terpadu, pencarian satu kolom untuk seluruh isi email, filter domain, detail email, compose, sent, dan settings. Lihat [`mobile/README.md`](mobile/README.md) untuk cara menjalankan dan status integrasinya.

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
| `DATABASE_URL` | URL Postgres/Neon untuk arsip email permanen dan pencarian isi |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | JSON service account Firebase untuk push native Android |
| `SENDER_EMAIL` | Alamat pengirim awal, harus pada domain yang terverifikasi |
| `SENDER_NAME` | Nama pengirim awal |
| `REPLY_TO` | Reply-to awal, opsional |
| `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` | Notifikasi inbox via Telegram, opsional |
| `NTFY_TOPIC` | Topik acak 32–64 karakter untuk push Android via ntfy.sh, opsional |

Set variabel yang sama di Vercel untuk Production. Jika `DASHBOARD_PASSWORD` atau `JWT_SECRET` kosong, login sengaja dinonaktifkan. Saat menambah webhook di Resend, pilih hanya event `email.received` dan URL `https://<project>.vercel.app/api/webhook/resend`; salin signing secret ke `RESEND_WEBHOOK_SECRET`.

## Menambah domain

1. Buka **Settings**, masukkan domain (misalnya `alte.codes`), lalu klik **Add Domain**.
2. Salin record DNS yang ditampilkan ke penyedia DNS domain. Klik **Verify DNS** dan refresh status sampai `verified`.
3. Bila ingin menerima email di domain itu, klik **Enable Inbox**, pasang record MX penerimaan yang muncul, lalu pastikan webhook Resend aktif. Mengubah MX utama dapat memindahkan seluruh email masuk dari penyedia lama; cek pengaturan domain dahulu.
4. Buka **Send**, pilih domain terverifikasi dan ketik nama alamat sebelum `@`. Alamat terakhir disimpan di browser sebagai pilihan awal.

Domain dan statusnya disimpan di Resend. Jika `DATABASE_URL` tersedia, webhook mengarsipkan email masuk dan email terkirim ke Postgres sehingga riwayat tidak mengikuti batas retensi Resend. Endpoint `POST /api/mail/sync` dapat dipakai sekali setelah database dibuat untuk mengarsipkan hingga 100 email masuk yang masih tersedia di Resend.

## Push Android tanpa VPS

Client Flutter memakai Firebase Cloud Messaging. Setelah login, token perangkat didaftarkan ke API dan disimpan di Neon. Webhook Resend mengarsipkan email, lalu mengirim notifikasi native yang memuat subjek dan alamat penerima. Saat notifikasi diketuk, aplikasi membuka email terkait. Alur ini berjalan di Vercel dan tidak memakai kuota email keluar Resend.

Konfigurasi Firebase Android berada di `mobile/android/app/google-services.json`. Kredensial server harus disimpan sebagai secret `FIREBASE_SERVICE_ACCOUNT_JSON` di Vercel dan tidak boleh masuk Git. Token perangkat lama yang ditolak Firebase dibersihkan otomatis.

Integrasi ntfy dan Telegram tetap tersedia sebagai cadangan bila environment terkait masih diisi. Payload ntfy tetap generik dan tidak membawa data email.

## Verifikasi sebelum rilis

```bash
npm run build
npm audit
npm run test:database
```

Uji login, daftar domain, kirim email dari setiap domain terverifikasi, inbox, dan webhook di lingkungan yang terhubung ke akun Resend sebenarnya.
