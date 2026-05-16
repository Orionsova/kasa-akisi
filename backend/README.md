# Kasa Akisi Backend

Bu klasor Flutter uygulamasinin kendi API altyapisidir. Ilk surum su yuzeyi kapsar:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/google`
- `POST /api/auth/apple` placeholder
- `GET /api/auth/profile`
- `GET/POST/PUT/DELETE /api/categories`
- `GET/POST/DELETE /api/transactions`

## Stack

- Express
- TypeScript
- Prisma
- PostgreSQL
- JWT

## Kurulum

1. `backend/.env.example` dosyasini kopyalayip `.env` olarak doldur.
2. PostgreSQL'i calistir:

```bash
cd backend
docker compose up -d
```

3. Paketleri yukle:

```bash
npm install
```

4. Prisma client ve migration:

```bash
npx prisma generate
npx prisma migrate dev --name init
```

5. Gelistirme sunucusu:

```bash
npm run dev
```

## Render Deploy

Bu backend Render'a deploy edilmeye hazir. Repo icinde [render.yaml](./render.yaml) var.

### 1. Veritabani ac

En temiz secenek `Neon` PostgreSQL:

1. Neon hesabı ac
2. Yeni project olustur
3. Connection string'i kopyala

### 2. Render web service ac

1. Render hesabina gir
2. `New +` > `Blueprint` sec
3. Bu GitHub repo'sunu bagla
4. Render `backend/render.yaml` dosyasini okuyup web service'i olustursun

Alternatif olarak `Web Service` ile manuel de acabilirsin:

- Root Directory: `backend`
- Build Command: `npm install && npm run prisma:generate && npm run build`
- Start Command: `npm run start:render`

### 3. Render environment variables

Sunlari gir:

- `DATABASE_URL` = Neon connection string
- `JWT_SECRET` = uzun rastgele guclu secret
- `GOOGLE_CLIENT_ID` = Google web client id
- `APPLE_AUDIENCE` = simdilik bos olabilir
- `JWT_EXPIRES_IN` = `7d`
- `NODE_ENV` = `production`

### 4. Ilk deploy

Deploy bitince su endpoint'i ac:

- `https://senin-render-adresin.onrender.com/api/health`

Donmesi gereken cevap:

```json
{
  "status": "ok",
  "service": "kasa-akisi-backend",
  "timestamp": "..."
}
```

## Flutter entegrasyonu

Flutter artik `dart-define` ile URL aliyor.

Gelistirme icin varsayilanlar:

- Android emulator: `http://10.0.2.2:4000/api`
- diger platformlar: `http://localhost:4000/api`

Production icin:

```bash
flutter run --dart-define=API_BASE_URL=https://senin-render-adresin.onrender.com/api
```

Google client id override etmek istersen:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://senin-render-adresin.onrender.com/api \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=senin-google-web-client-id
```

## Google giris

`POST /api/auth/google` hazir. Bunun calismasi icin:

- Google Cloud Console'da OAuth client
- backend `.env` icinde `GOOGLE_CLIENT_ID`
- Flutter tarafinda da ayni client zinciri

## Apple giris

Route hazir ama dogrulama henuz eklenmedi. Bir sonraki asamada:

- Apple Developer Service ID
- Key / Team ID / Client ID
- identity token verification

eklenecek.

## Sonraki mantikli adim

1. Render + Neon deploy'unu tamamlamak
2. Flutter'ı production URL ile calistirmak
3. Login akisini email/password ile test etmek
4. Google login'i kendi credential'larinla acmak
5. Sonra credit cards / investments / recurring payments tablolarini backend'e tasimak
