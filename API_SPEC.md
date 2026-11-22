---

# 📚 Complete API Specification - RS Permata Sehat

> **Hospital Management System - Digital Control Schedule** > Last Updated: **February 8, 2026** (Final Release Candidate)

---

## 🏆 Project Status Overview

| Metric | Count | Status |
| --- | --- | --- |
| **Total Endpoints** | **65** | 🎯 Target |
| **Implemented** | **62** | ✅ Functional |
| **Pending** | **3** | ⚠️ External Dependency (Email) |
| **Completion Rate** | **95%** | 🚀 **Production Ready** |

---

## ✅ Implementation Progress (Updated)

### 1. Authentication

| Endpoint | Status | Access |
| --- | --- | --- |
| `POST /api/auth/register` | ✅ **Done** | Public |
| `POST /api/auth/login` | ✅ **Done** | Public |
| `POST /api/auth/change-password` | ✅ **Done** | Auth User |
| `POST /api/auth/logout` | ✅ **Done** | Auth User |
| `POST /api/auth/forgot-password` | ⏳ Pending | Public (Needs Email Server) |

### 2. User Management

| Endpoint | Status | Access |
| --- | --- | --- |
| `GET /api/users/me` | ✅ **Done** | Auth User |
| `PUT /api/users/me` | ✅ **Done** | Auth User |
| `GET /api/users` | ✅ **Done** | Admin |
| `POST /api/users` | ✅ **Done** | Admin |
| `DELETE /api/users/:id` | ✅ **Done** | Admin |
| `GET /api/users/patients` | ✅ **Done** | Doctor/Admin |
| `GET /api/users/patients/:id` | ✅ **Done** | Doctor/Admin |

### 3. Appointments

| Endpoint | Status | Access |
| --- | --- | --- |
| `GET /api/appointments` | ✅ **Done** | All (Scoped) |
| `GET /api/appointments/today` | ✅ **Done** | Auth User (Scoped) |
| `POST /api/appointments` | ✅ **Done** | All |
| `GET /api/appointments/:id` | ✅ **Done** | Owner/Admin |
| `DELETE /api/appointments/:id` | ✅ **Done** | Owner/Admin (Cancel) |
| `PUT /api/appointments/:id/approve` | ✅ **Done** | Admin |
| `PUT /api/appointments/:id/reject` | ✅ **Done** | Admin |
| `PUT /api/appointments/:id/complete` | ✅ **Done** | Doctor |

### 4. Doctors

| Endpoint | Status | Access |
| --- | --- | --- |
| `GET /api/doctors` | ✅ **Done** | Auth User (Safe DTO) |
| `GET /api/doctors/me` | ✅ **Done** | Doctor |
| `PUT /api/doctors/me` | ✅ **Done** | Doctor |
| `POST /api/doctors` | ✅ **Done** | Admin |
| `PUT /api/doctors/:id` | ✅ **Done** | Admin |
| `DELETE /api/doctors/:id` | ✅ **Done** | Admin |

### 5. Medical Records

| Endpoint | Status | Access |
| --- | --- | --- |
| `GET /api/medical-records` | ✅ **Done** | Doctor/Patient (Scoped) |
| `GET /api/medical-records/patient/:id` | ✅ **Done** | Doctor/Admin |
| `POST /api/medical-records` | ✅ **Done** | Doctor |
| `GET /api/medical-records/:id` | ✅ **Done** | Owner/Doctor |
| `PUT /api/medical-records/:id` | ✅ **Done** | Doctor (Owner)/Admin |
| `DELETE /api/medical-records/:id` | ✅ **Done** | Admin |

### 6. Clinical Notes (Internal)

| Endpoint | Status | Access |
| --- | --- | --- |
| `GET /api/clinical-notes` | ✅ **Done** | Doctor (Own)/Admin |
| `POST /api/clinical-notes` | ✅ **Done** | Doctor |
| `GET /api/clinical-notes/:id` | ✅ **Done** | Doctor |
| `PUT /api/clinical-notes/:id` | ✅ **Done** | Doctor (Own)/Admin |
| `DELETE /api/clinical-notes/:id` | ✅ **Done** | Admin |

### 7. Schedules

| Endpoint | Status | Access |
| --- | --- | --- |
| `GET /api/schedules` | ✅ **Done** | Auth User |
| `POST /api/schedules` | ✅ **Done** | Doctor |
| `PUT /api/schedules/:id` | ✅ **Done** | Doctor |
| `DELETE /api/schedules/:id` | ✅ **Done** | Doctor |

### 8. Health Updates (Tracker)

| Endpoint | Status | Access |
| --- | --- | --- |
| `GET /api/health-updates` | ✅ **Done** | Patient/Doctor |
| `POST /api/health-updates` | ✅ **Done** | Patient |
| `DELETE /api/health-updates/:id` | ✅ **Done** | Owner/Admin |

### 9. Messaging

| Endpoint | Status | Access |
| --- | --- | --- |
| `GET /api/messages` | ✅ **Done** | Auth User |
| `POST /api/messages` | ✅ **Done** | Auth User |
| `PUT /api/messages/:id/read` | ✅ **Done** | Recipient |
| `DELETE /api/messages/:id` | ✅ **Done** | Sender/Admin |

### 10. Analytics

| Endpoint | Status | Access |
| --- | --- | --- |
| `GET /api/analytics/dashboard` | ✅ **Done** | Admin |
| `GET /api/analytics/appointments` | ✅ **Done** | Admin |
| `GET /api/analytics/doctors` | ✅ **Done** | Admin |
| `GET /api/analytics/health` | ✅ **Done** | Admin |

### 11. System & Files

| Endpoint | Status | Access |
| --- | --- | --- |
| `POST /api/upload` | ✅ **Done** | Auth User |
| `GET /api/system-alerts` | ✅ **Done** | Admin |
| `POST /api/system-alerts/:id/resolve` | ✅ **Done** | Admin |

---

## 📋 Remaining Tasks Checklist

### 🔴 Critical (Must Have)

> **Status:** 🎉 **100% COMPLETE**

### 🟠 High Priority

> **Status:** 🎉 **100% COMPLETE**

### 🟡 Medium Priority

> **Status:** 🎉 **100% COMPLETE**

### 🟢 Low Priority (Optional)

* [ ] `POST /api/auth/forgot-password` (Pending: Requires SMTP/Email Service integration)

---
## Kontrak aplikasi pasien iOS

Bagian ini mengikuti route Vapor yang dipakai aplikasi pasien. Semua endpoint di tabel berikut memerlukan `Authorization: Bearer <token>`. `POST /api/auth/login` dan `POST /api/auth/register` bersifat publik. Tanggal klinik memakai `YYYY-MM-DD` dan jam lokal memakai `HH:mm` di `Asia/Jakarta`. Timestamp JSON memakai ISO 8601. `practice.fee` adalah tarif dalam satuan penuh `practice.currency`, misalnya `125000` untuk IDR.

| Layar | Kontrak |
| --- | --- |
| Doctor Search List | `GET /api/doctors?q=&specialty=&favorites=true`. Respons menambah `userId`, `avatarURL`, `reviewCount`, `totalPatients`, `practice`, `isFavorite` dan `nextAvailable` dalam 14 hari ke depan. `PUT`/`DELETE /api/doctors/:id/favorite` mengembalikan `204`. |
| Doctor Details | `GET /api/doctors/:id` memberi profil. `GET /api/schedules?doctorId=…` memberi jadwal mingguan. `GET /api/doctors/:id/availability?from=…&to=…` menerima rentang inklusif maksimal 31 hari dan memberi `{date,time,endTime,available}` untuk tiap slot 30 menit. Slot yang sudah lewat atau terisi mempunyai `available: false`. |
| Appointment Details dan Make Appointment | `POST /api/appointments` dengan `{doctorId,date,time,reason,complaints?}`. Respons menambah `endTime`, `referenceNumber`, dokter, dan status `pending`. Header `Idempotency-Key` opsional. Retry dengan key yang sama untuk pasien dan dokter yang sama mengambil booking yang sudah tersimpan. Slot sudah terisi memberi `409`. |
| Manage Appointment dan Patient Dashboard | `GET /api/appointments?status=…`, `GET /api/appointments/:id`, dan `PATCH /api/appointments/:id` dengan `{date,time}`. Jadwal baru mengembalikan status `pending`. Tab Upcoming/History memakai `date`, `time`, dan `status`. |
| Cancel Appointment dan Cancellation Alert | `POST /api/appointments/:id/cancellation-requests` dengan `{reason,note?}` menghasilkan `cancellation_requested`. Admin memakai `PUT` pada path yang sama dengan `{approved}`. Persetujuan mengubah status menjadi `cancelled` dan slot kembali tersedia. Penolakan memulihkan status sebelumnya. `DELETE /api/appointments/:id` tetap tersedia untuk penghapusan langsung. |
| Patient Dashboard dan Profile Notifications | `GET /api/notifications?unread=true`, `PUT /api/notifications/:id/read`, `GET`/`PUT /api/users/me/notification-settings` dengan `{appointmentUpdates}`. Approval booking dan hasil pembatalan membuat notifikasi dalam aplikasi. |
| Medical Record List dan Diagnosis Details | `GET /api/medical-records?q=&type=diagnosis` atau `type=vaccination`. Detail `GET /api/medical-records/:id` memuat appointment dan dokter, severity, tag gejala, dan resep terstruktur kalau tersedia. `GET /api/medical-records/:id/documents` memberi lampiran. Gabungkan daftar rekam medis dengan daftar lab untuk All Records. |
| Lab Result | `GET /api/lab-results`, `GET /api/lab-results/:id`, `GET /api/lab-results/:id/pdf`. Petugas menerbitkan via `POST /api/lab-results` dengan `{patientId,title,laboratory,collectedAt,panels,alert?,doctorNote?,pdfDocumentId?}`. Setiap panel menerima `{name,status?,summary?,measurements}` dan setiap hasil `{name,value,unit?,referenceRange?,status?}`. `pdfPath` muncul jika PDF klinis milik pasien ditautkan. |
| Documents & BPJS dan Upload Docs | `GET /api/documents`, `GET /api/documents/history`, `POST /api/documents`, `PUT /api/documents/:id`, `DELETE /api/documents/:id`, dan `GET /api/documents/:id/download`. Buat dengan multipart `name`, `category`, `file`, `cardNumber?`. Update boleh JSON bila hanya mengubah metadata, atau multipart bila mengganti file. Kategori `bpjs`, `insurance`, `familyCard`, `idCard`, `other`. File pasien PDF/JPEG/PNG hingga 5 MiB. Petugas bisa mengirim `category=clinicalAttachment` dengan `patientId` dan `medicalRecordId?`. Lampiran klinis juga menerima DOCX. Unduhan memerlukan JWT. |
| Health Tracker dan Log Vitals | `GET /api/health-updates?from=&to=&metric=&limit=&page=`, `GET /api/health-updates/:id`, `POST /api/health-updates` dengan `date`, `measuredAt?`, dan satu atau beberapa pengukuran. Filter `metric` menerima `bloodPressure`, `heartRate`, `weight`. Grafik dan statistik bisa dihitung dari histori, dengan fallback dari `measuredAt` ke `createdAt` untuk entri lama. |
| Today’s Care Plan | `GET /api/care-plan?date=…`, `PUT /api/care-plan/:recordId/:medicationId/taken` dengan `{date,time}`. Petugas mengisi `medications` saat membuat atau memperbarui rekam medis. Setiap obat memakai `{id,name,dose,category?,instructions?,startsOn,endsOn,times}`. |
| Message Doctor dan Quick Access | `GET /api/messages/conversations?q=…` memberi `latestMessage` dan `unreadCount`. Detail thread memakai `GET /api/messages?peerId=…&limit=…&page=…`. `POST /api/messages` menerima `{receiverId,content}`. Isi `receiverId` dengan `userId` dari profil dokter. `PUT /api/messages/:id/read` menandai pesan masuk. |
| Profile Screen | `GET`/`PUT /api/users/me` memuat biodata dan `avatarURL`. `patientNumber` menggunakan UUID akun dengan prefiks `PS-`. `GET /api/help-center` memberi topik bantuan. Ganti password dan logout memakai route auth yang sudah ada. |

Untuk database existing, jalankan `swift run rumahsakit migrate --yes` sekali sebelum menaikkan replika yang memakai kolom baru. Pada Docker Compose, jalankan migrasi satu kali dengan `docker compose run --rm app-1 migrate --env production --yes` setelah MySQL siap. Workflow untuk demo memakai notifikasi dalam aplikasi dan PDF yang diunggah petugas.
