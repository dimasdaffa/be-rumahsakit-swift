# Tes HTTP RS Permata Sehat

Suite ini memakai API Vapor di balik Nginx Docker pada `http://localhost:8081`.
Setiap bagian file Hurl memiliki komentar tentang perilaku yang diuji. Token dan ID
diambil dari respons supaya tes bisa dijalankan ulang tanpa UUID dari collection lama.

| File | Cakupan |
| --- | --- |
| `00-service.hurl` | Health, header upstream Nginx, OpenAPI, Swagger UI, dan respons `401` tanpa Bearer token |
| `10-patient-workflow.hurl` | Auth, profil, dokter, jadwal, favorit, booking, reschedule, pembatalan, notifikasi, diagnosis, care plan, dokumen, PDF lab, vital, chat, dan upload lama |
| `20-admin.hurl` | CRUD pengguna dan dokter, analitik, serta pembuatan dan penyelesaian system alert |
| `30-booking-race.hurl` | Dua worker meminta slot yang sama. Runner memeriksa bahwa hasil gabungannya `200` dan `409`. |

## Menjalankan

Jalankan dari root repo dengan stack Docker Compose aktif. Runner memakai Hurl
yang sudah terpasang atau image resmi Hurl 8.1.0. Mode lengkap juga memakai
`jq` untuk membandingkan dua respons booking.

```sh
./Tests/hurl/run.sh smoke
HURL_ADMIN_PASSWORD='<password admin lokal>' ./Tests/hurl/run.sh
```

`HURL_ADMIN_EMAIL` bisa diisi jika alamat admin lokal berbeda dari
`admin@rumahsakit.com`. `BASE_URL` bisa diisi untuk mengganti port. Runner
memasukkan password sebagai secret Hurl dan memakai zona waktu Asia/Jakarta
untuk memilih jadwal besok.

Jika stack baru dibangun dan migrasi database belum diterapkan, jalankan sekali
setelah MySQL siap.

```sh
docker compose exec -T app-1 ./rumahsakit migrate --env production --yes
```

Mode lengkap membuat data dummy bertanda `HURL-<run-id>` di database yang
dituju. Gunakan database lokal untuk pengujian. Skenario penghapusan memakai ID
data yang dibuat pada run itu. Sebagian fixture, termasuk laporan lab dan histori
pembatalan, tetap ada agar alur baca bisa diperiksa. File PDF fixture sintetis.
Jika tes gagal, Hurl menunjuk file dan baris assertion yang perlu diperiksa.

Collection Postman lama menjadi acuan cakupan. Request di sini memakai route
dan payload dari [kontrak API saat ini](../../API_SPEC.md#kontrak-aplikasi-pasien-ios).
