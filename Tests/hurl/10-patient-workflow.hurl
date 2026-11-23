# 01 · Login dan profil. Buat identitas unik, lalu tangkap JWT dan ID dari respons.

POST {{base_url}}/api/auth/login
[Multipart]
email: {{admin_email}}
password: {{admin_password}}
HTTP 200
[Captures]
admin_token: jsonpath "$.token"
[Asserts]
jsonpath "$.token" exists
jsonpath "$.user.passwordHash" not exists

POST {{base_url}}/api/auth/register
{"name":"HURL-{{run_id}} patient","email":"hurl-patient-{{run_id}}@example.test","password":"hurl-fixture-{{run_id}}","role":"patient"}
HTTP 200
[Captures]
patient_id: jsonpath "$.id"
[Asserts]
jsonpath "$.role" == "patient"
jsonpath "$.passwordHash" not exists

POST {{base_url}}/api/auth/login
[Multipart]
email: hurl-patient-{{run_id}}@example.test
password: hurl-fixture-{{run_id}}
HTTP 200
[Captures]
patient_token: jsonpath "$.token"
[Asserts]
jsonpath "$.token" exists
jsonpath "$.user.passwordHash" not exists

POST {{base_url}}/api/auth/register
{"name":"HURL-{{run_id}} other","email":"hurl-other-{{run_id}}@example.test","password":"hurl-fixture-{{run_id}}","role":"patient"}
HTTP 200
[Captures]
other_id: jsonpath "$.id"
[Asserts]
jsonpath "$.role" == "patient"
jsonpath "$.passwordHash" not exists

POST {{base_url}}/api/auth/login
[Multipart]
email: hurl-other-{{run_id}}@example.test
password: hurl-fixture-{{run_id}}
HTTP 200
[Captures]
other_token: jsonpath "$.token"
[Asserts]
jsonpath "$.token" exists
jsonpath "$.user.passwordHash" not exists

POST {{base_url}}/api/auth/register
{"name":"Duplicate fixture","email":"hurl-patient-{{run_id}}@example.test","password":"hurl-fixture-{{run_id}}","role":"patient"}
HTTP 409

POST {{base_url}}/api/auth/login
{"email":"hurl-patient-{{run_id}}@example.test","password":"wrong-fixture-password"}
HTTP 401

GET {{base_url}}/api/users/me
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$.id" == "{{patient_id}}"
jsonpath "$.patientNumber" startsWith "PS-"

PUT {{base_url}}/api/users/me
Authorization: Bearer {{patient_token}}
{"city":"Jakarta","avatarURL":"/uploads/hurl-avatar.png"}
HTTP 200
[Asserts]
jsonpath "$.city" == "Jakarta"
jsonpath "$.avatarURL" == "/uploads/hurl-avatar.png"

GET {{base_url}}/api/help-center
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].title" exists

GET {{base_url}}/api/users/me/notification-settings
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$.appointmentUpdates" == true

# 02 · Dokter dan jadwal. Dua role berbeda diperlukan untuk menyiapkan jam praktik yang muncul di aplikasi.

POST {{base_url}}/api/doctors
Authorization: Bearer {{admin_token}}
{
  "name": "HURL-{{run_id}} doctor",
  "email": "hurl-doctor-{{run_id}}@example.test",
  "password": "hurl-fixture-{{run_id}}",
  "phone": "0000000000",
  "specialty": "Cardiology",
  "status": "active",
  "experience": 12,
  "rating": 4.8,
  "totalPatients": 123,
  "reviewCount": 21,
  "practice": {
    "name": "Demo Hospital",
    "room": "201",
    "fee": 125000,
    "currency": "IDR"
  }
}
HTTP 200
[Captures]
doctor_id: jsonpath "$.id"
doctor_user_id: jsonpath "$.user.id"
[Asserts]
jsonpath "$.specialty" == "Cardiology"

POST {{base_url}}/api/auth/login
[Multipart]
email: hurl-doctor-{{run_id}}@example.test
password: hurl-fixture-{{run_id}}
HTTP 200
[Captures]
doctor_token: jsonpath "$.token"
[Asserts]
jsonpath "$.token" exists
jsonpath "$.user.passwordHash" not exists

GET {{base_url}}/api/doctors/me
Authorization: Bearer {{doctor_token}}
HTTP 200
[Asserts]
jsonpath "$.id" == "{{doctor_id}}"
jsonpath "$.userId" == "{{doctor_user_id}}"

PUT {{base_url}}/api/doctors/me
Authorization: Bearer {{doctor_token}}
{"bio":"HURL fixture","experience":13}
HTTP 200
[Asserts]
jsonpath "$.experience" == 13

POST {{base_url}}/api/schedules
Authorization: Bearer {{doctor_token}}
{"dayOfWeek":"{{visit_weekday}}","startTime":"09:00","endTime":"10:30","isAvailable":true}
HTTP 200
[Captures]
schedule_id: jsonpath "$.id"

PUT {{base_url}}/api/schedules/{{schedule_id}}
Authorization: Bearer {{doctor_token}}
{"endTime":"11:00"}
HTTP 200
[Asserts]
jsonpath "$.endTime" == "11:00"

GET {{base_url}}/api/schedules?doctorId={{doctor_id}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{schedule_id}}"
jsonpath "$[0].dayOfWeek" == "{{visit_weekday}}"

PUT {{base_url}}/api/doctors/{{doctor_id}}/favorite
Authorization: Bearer {{patient_token}}
HTTP 204

GET {{base_url}}/api/doctors?q={{run_id}}&specialty=Cardiology&favorites=true
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{doctor_id}}"
jsonpath "$[0].isFavorite" == true
jsonpath "$[0].nextAvailable.time" == "09:00"

GET {{base_url}}/api/doctors/{{doctor_id}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$.rating" == 4.8
jsonpath "$.practice.room" == "201"
jsonpath "$.practice.currency" == "IDR"
jsonpath "$.totalPatients" == 123

DELETE {{base_url}}/api/doctors/{{doctor_id}}/favorite
Authorization: Bearer {{patient_token}}
HTTP 204

GET {{base_url}}/api/doctors?q={{run_id}}&favorites=true
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$" isEmpty

GET {{base_url}}/api/doctors/{{doctor_id}}/availability?from={{visit_date}}&to={{visit_date}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$" count == 4
jsonpath "$[0].time" == "09:00"
jsonpath "$[0].endTime" == "09:30"
jsonpath "$[0].available" == true

# 03 · Booking. Retry dengan idempotency key harus memakai ID yang sama. Pasien lain mendapat konflik untuk slot yang terisi.

POST {{base_url}}/api/appointments
Authorization: Bearer {{patient_token}}
Idempotency-Key: HURL-{{run_id}}-retry
{"doctorId":"{{doctor_id}}","date":"{{visit_date}}","time":"09:00","reason":"Kunjungan dummy","complaints":"Fixture HURL-{{run_id}}"}
HTTP 200
[Captures]
appointment_id: jsonpath "$.id"
[Asserts]
jsonpath "$.status" == "pending"
jsonpath "$.endTime" == "09:30"
jsonpath "$.referenceNumber" startsWith "REF-"

POST {{base_url}}/api/appointments
Authorization: Bearer {{patient_token}}
Idempotency-Key: HURL-{{run_id}}-retry
{"doctorId":"{{doctor_id}}","date":"{{visit_date}}","time":"09:00","reason":"Kunjungan dummy","complaints":"Fixture HURL-{{run_id}}"}
HTTP 200
[Asserts]
jsonpath "$.id" == "{{appointment_id}}"

POST {{base_url}}/api/appointments
Authorization: Bearer {{other_token}}
{"doctorId":"{{doctor_id}}","date":"{{visit_date}}","time":"09:00","reason":"Kunjungan dummy","complaints":"Fixture HURL-{{run_id}}"}
HTTP 409

POST {{base_url}}/api/appointments
Authorization: Bearer {{patient_token}}
{"doctorId":"{{doctor_id}}","date":"{{visit_date}}","time":"08:30","reason":"Kunjungan dummy","complaints":"Fixture HURL-{{run_id}}"}
HTTP 422

GET {{base_url}}/api/appointments/{{appointment_id}}
Authorization: Bearer {{other_token}}
HTTP 403

GET {{base_url}}/api/appointments/{{appointment_id}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$.doctor.id" == "{{doctor_id}}"
jsonpath "$.patientId" == "{{patient_id}}"

GET {{base_url}}/api/appointments/today
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$" isEmpty

PUT {{base_url}}/api/appointments/{{appointment_id}}/approve
Authorization: Bearer {{patient_token}}
HTTP 403

PUT {{base_url}}/api/appointments/{{appointment_id}}/approve
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "approved"

PATCH {{base_url}}/api/appointments/{{appointment_id}}
Authorization: Bearer {{patient_token}}
{"date":"{{visit_date}}","time":"09:30"}
HTTP 200
[Asserts]
jsonpath "$.status" == "pending"
jsonpath "$.time" == "09:30"

GET {{base_url}}/api/doctors/{{doctor_id}}/availability?from={{visit_date}}&to={{visit_date}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].available" == true
jsonpath "$[1].available" == false

# 04 · Pembatalan. Penolakan memulihkan status, persetujuan menyimpan histori dan membebaskan slot.

POST {{base_url}}/api/appointments/{{appointment_id}}/cancellation-requests
Authorization: Bearer {{patient_token}}
{"reason":"change_of_plans","note":"HURL fixture"}
HTTP 200
[Asserts]
jsonpath "$.status" == "cancellation_requested"
jsonpath "$.cancellationReason" == "change_of_plans"

GET {{base_url}}/api/doctors/{{doctor_id}}/availability?from={{visit_date}}&to={{visit_date}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[1].available" == false

PUT {{base_url}}/api/appointments/{{appointment_id}}/cancellation-requests
Authorization: Bearer {{admin_token}}
{"approved":false}
HTTP 200
[Asserts]
jsonpath "$.status" == "pending"

POST {{base_url}}/api/appointments/{{appointment_id}}/cancellation-requests
Authorization: Bearer {{patient_token}}
{"reason":"change_of_plans"}
HTTP 200
[Asserts]
jsonpath "$.status" == "cancellation_requested"

PUT {{base_url}}/api/appointments/{{appointment_id}}/cancellation-requests
Authorization: Bearer {{admin_token}}
{"approved":true}
HTTP 200
[Asserts]
jsonpath "$.status" == "cancelled"

GET {{base_url}}/api/appointments?status=cancelled
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{appointment_id}}"
jsonpath "$[0].status" == "cancelled"

GET {{base_url}}/api/doctors/{{doctor_id}}/availability?from={{visit_date}}&to={{visit_date}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[1].available" == true

GET {{base_url}}/api/notifications?unread=true
Authorization: Bearer {{patient_token}}
HTTP 200
[Captures]
notification_id: jsonpath "$[0].id"
[Asserts]
jsonpath "$[*].type" contains "cancelled"
jsonpath "$[*].type" contains "cancellation_declined"
jsonpath "$[*].type" contains "approved"

PUT {{base_url}}/api/notifications/{{notification_id}}/read
Authorization: Bearer {{patient_token}}
HTTP 204

GET {{base_url}}/api/notifications?unread=true
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[*].id" not contains "{{notification_id}}"

PUT {{base_url}}/api/users/me/notification-settings
Authorization: Bearer {{patient_token}}
{"appointmentUpdates":false}
HTTP 200
[Asserts]
jsonpath "$.appointmentUpdates" == false

GET {{base_url}}/api/users/me/notification-settings
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$.appointmentUpdates" == false

# 05 · Kasus admin lainnya dan kunjungan selesai. Hapus hanya appointment kedua yang dibuat tes.

POST {{base_url}}/api/appointments
Authorization: Bearer {{patient_token}}
{"doctorId":"{{doctor_id}}","date":"{{visit_date}}","time":"10:30","reason":"Kunjungan dummy","complaints":"Fixture HURL-{{run_id}}"}
HTTP 200
[Captures]
rejected_id: jsonpath "$.id"

PUT {{base_url}}/api/appointments/{{rejected_id}}/reject
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "rejected"

DELETE {{base_url}}/api/appointments/{{rejected_id}}
Authorization: Bearer {{patient_token}}
HTTP 204

GET {{base_url}}/api/appointments/{{rejected_id}}
Authorization: Bearer {{patient_token}}
HTTP 404

POST {{base_url}}/api/appointments
Authorization: Bearer {{patient_token}}
{"doctorId":"{{doctor_id}}","date":"{{visit_date}}","time":"09:00","reason":"Kunjungan rekam medis","complaints":"Fixture HURL-{{run_id}}"}
HTTP 200
[Captures]
completed_id: jsonpath "$.id"

PUT {{base_url}}/api/appointments/{{completed_id}}/approve
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "approved"

PUT {{base_url}}/api/appointments/{{completed_id}}/complete
Authorization: Bearer {{doctor_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "completed"

GET {{base_url}}/api/notifications?unread=true
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$" count == 2

# 06 · Rekam medis dan care plan. Resep dummy menjadi dosis terjadwal, dan retry mempertahankan waktu pencatatan.

POST {{base_url}}/api/medical-records
Authorization: Bearer {{doctor_token}}
{
  "appointmentId": "{{completed_id}}",
  "diagnosis": "HURL-{{run_id}} diagnosis",
  "symptoms": "Fixture",
  "treatment": "Fixture",
  "followUpRequired": false,
  "recordType": "diagnosis",
  "severity": "moderate",
  "symptomTags": [
    "Fixture"
  ],
  "medications": [
    {
      "id": "a12dbbd6-72d3-4b69-ba61-{{run_id}}",
      "name": "Obat dummy",
      "dose": "Dosis dummy",
      "startsOn": "{{today}}",
      "endsOn": "{{today}}",
      "times": [
        "14:00"
      ]
    }
  ]
}
HTTP 200
[Captures]
record_id: jsonpath "$.id"

PUT {{base_url}}/api/medical-records/{{record_id}}
Authorization: Bearer {{doctor_token}}
{"severity":"mild"}
HTTP 200
[Asserts]
jsonpath "$.severity" == "mild"

GET {{base_url}}/api/medical-records/{{record_id}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$.severity" == "mild"
jsonpath "$.symptomTags[0]" == "Fixture"
jsonpath "$.medications[0].name" == "Obat dummy"

GET {{base_url}}/api/medical-records/{{record_id}}
Authorization: Bearer {{other_token}}
HTTP 403

GET {{base_url}}/api/medical-records?type=diagnosis&q={{run_id}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{record_id}}"

GET {{base_url}}/api/medical-records/patient/{{patient_id}}
Authorization: Bearer {{doctor_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{record_id}}"

GET {{base_url}}/api/care-plan?date={{today}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].recordId" == "{{record_id}}"
jsonpath "$[0].time" == "14:00"

PUT {{base_url}}/api/care-plan/{{record_id}}/a12dbbd6-72d3-4b69-ba61-{{run_id}}/taken
Authorization: Bearer {{patient_token}}
{"date":"{{today}}","time":"14:00"}
HTTP 200
[Captures]
taken_at: jsonpath "$.takenAt"
[Asserts]
jsonpath "$.takenAt" isIsoDate

PUT {{base_url}}/api/care-plan/{{record_id}}/a12dbbd6-72d3-4b69-ba61-{{run_id}}/taken
Authorization: Bearer {{patient_token}}
{"date":"{{today}}","time":"14:00"}
HTTP 200
[Asserts]
jsonpath "$.takenAt" == "{{taken_at}}"

POST {{base_url}}/api/medical-records
Authorization: Bearer {{doctor_token}}
{
  "appointmentId": "{{completed_id}}",
  "diagnosis": "HURL-{{run_id}} diagnosis",
  "symptoms": "Fixture",
  "treatment": "Fixture",
  "followUpRequired": false,
  "recordType": "vaccination"
}
HTTP 200
[Captures]
vaccination_id: jsonpath "$.id"

GET {{base_url}}/api/medical-records?type=vaccination
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{vaccination_id}}"

DELETE {{base_url}}/api/medical-records/{{vaccination_id}}
Authorization: Bearer {{admin_token}}
HTTP 204

# 07 · Catatan klinis internal. Catatan berbeda dari rekam medis yang boleh dilihat pasien.

POST {{base_url}}/api/clinical-notes
Authorization: Bearer {{doctor_token}}
{
  "patientId": "{{patient_id}}",
  "appointmentId": "{{completed_id}}",
  "diagnosis": "Fixture",
  "treatment": "Fixture",
  "notes": "Internal HURL-{{run_id}}",
  "status": "draft"
}
HTTP 200
[Captures]
note_id: jsonpath "$.id"

GET {{base_url}}/api/clinical-notes
Authorization: Bearer {{doctor_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{note_id}}"

GET {{base_url}}/api/clinical-notes/{{note_id}}
Authorization: Bearer {{patient_token}}
HTTP 403

PUT {{base_url}}/api/clinical-notes/{{note_id}}
Authorization: Bearer {{doctor_token}}
{"status":"completed"}
HTTP 200
[Asserts]
jsonpath "$.status" == "completed"

GET {{base_url}}/api/clinical-notes/{{note_id}}
Authorization: Bearer {{doctor_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "completed"

DELETE {{base_url}}/api/clinical-notes/{{note_id}}
Authorization: Bearer {{admin_token}}
HTTP 204

# 08 · Dokumen privat. PDF sintetis bisa diunduh pemilik, diperbarui, lalu ditampilkan di histori setelah dihapus.

POST {{base_url}}/api/documents
Authorization: Bearer {{patient_token}}
[Multipart]
name: BPJS HURL-{{run_id}}
category: bpjs
cardNumber: 000001
file: file,fixtures/sample.pdf; application/pdf
HTTP 200
[Captures]
document_id: jsonpath "$.id"
download_path: jsonpath "$.downloadPath"
[Asserts]
jsonpath "$.mediaType" == "application/pdf"

POST {{base_url}}/api/documents
Authorization: Bearer {{patient_token}}
[Multipart]
name: Unsupported HURL-{{run_id}}
category: other
file: file,fixtures/sample.txt; text/plain
HTTP 415

GET {{base_url}}/api/documents
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{document_id}}"

GET {{base_url}}{{download_path}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
header "Content-Type" contains "application/pdf"
bytes startsWith hex,255044462d;

GET {{base_url}}{{download_path}}
Authorization: Bearer {{other_token}}
HTTP 403

GET {{base_url}}{{download_path}}
Authorization: Bearer {{doctor_token}}
HTTP 403

PUT {{base_url}}/api/documents/{{document_id}}
Authorization: Bearer {{patient_token}}
{"name":"BPJS diperbarui HURL-{{run_id}}","category":"bpjs","cardNumber":"000002"}
HTTP 200
[Asserts]
jsonpath "$.cardNumber" == "000002"

DELETE {{base_url}}/api/documents/{{document_id}}
Authorization: Bearer {{patient_token}}
HTTP 204

GET {{base_url}}/api/documents
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$" isEmpty

GET {{base_url}}/api/documents/history
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{document_id}}"
jsonpath "$[0].deletedAt" isIsoDate

GET {{base_url}}{{download_path}}
Authorization: Bearer {{patient_token}}
HTTP 404

# 09 · Hasil lab. Tautkan PDF klinis milik pasien, lalu periksa panel, lampiran, dan akses unduh.

POST {{base_url}}/api/documents
Authorization: Bearer {{doctor_token}}
[Multipart]
name: Lab HURL-{{run_id}}
category: clinicalAttachment
patientId: {{patient_id}}
medicalRecordId: {{record_id}}
file: file,fixtures/sample.pdf; application/pdf
HTTP 200
[Captures]
lab_document_id: jsonpath "$.id"

GET {{base_url}}/api/medical-records/{{record_id}}/documents
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{lab_document_id}}"

POST {{base_url}}/api/lab-results
Authorization: Bearer {{doctor_token}}
{
  "patientId": "{{patient_id}}",
  "title": "Lab HURL-{{run_id}}",
  "laboratory": "Demo Lab",
  "collectedAt": "{{today}}T00:30:00Z",
  "panels": [
    {
      "name": "Panel dummy",
      "summary": "Hasil sintetis",
      "measurements": [
        {
          "name": "Nilai A",
          "value": "123",
          "unit": "contoh"
        }
      ]
    }
  ],
  "doctorNote": "Catatan dummy",
  "pdfDocumentId": "{{lab_document_id}}"
}
HTTP 200
[Captures]
lab_id: jsonpath "$.id"
[Asserts]
jsonpath "$.panels[0].measurements[0].value" == "123"

GET {{base_url}}/api/lab-results
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{lab_id}}"

GET {{base_url}}/api/lab-results/{{lab_id}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$.doctorNote" == "Catatan dummy"
jsonpath "$.laboratory" == "Demo Lab"

GET {{base_url}}/api/lab-results/{{lab_id}}/pdf
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
header "Content-Type" contains "application/pdf"
bytes startsWith hex,255044462d;

GET {{base_url}}/api/lab-results/{{lab_id}}/pdf
Authorization: Bearer {{other_token}}
HTTP 403

DELETE {{base_url}}/api/documents/{{lab_document_id}}
Authorization: Bearer {{doctor_token}}
HTTP 409

# 10 · Health Tracker. Kirim tiga jenis pengukuran, cek filter, lalu hapus hasil tes sendiri.

POST {{base_url}}/api/health-updates
Authorization: Bearer {{patient_token}}
{"date":"{{today}}","measuredAt":"{{today}}T00:30:00Z","weight":72.1,"heartRate":72,"bloodPressure":"120/80"}
HTTP 200
[Captures]
vital_id: jsonpath "$.id"

GET {{base_url}}/api/health-updates?metric=weight&from={{today}}&to={{today}}&limit=5&page=1
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{vital_id}}"
jsonpath "$[0].weight" == 72.1

GET {{base_url}}/api/health-updates?metric=heartRate&from={{today}}&to={{today}}&limit=5&page=1
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{vital_id}}"
jsonpath "$[0].heartRate" == 72

GET {{base_url}}/api/health-updates?metric=bloodPressure&from={{today}}&to={{today}}&limit=5&page=1
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{vital_id}}"
jsonpath "$[0].bloodPressure" == "120/80"

GET {{base_url}}/api/health-updates/{{vital_id}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$.bloodPressure" == "120/80"
jsonpath "$.measuredAt" isIsoDate

GET {{base_url}}/api/health-updates/{{vital_id}}
Authorization: Bearer {{other_token}}
HTTP 403

GET {{base_url}}/api/users/patients
Authorization: Bearer {{doctor_token}}
HTTP 200
[Asserts]
jsonpath "$[*].id" contains "{{patient_id}}"
jsonpath "$[*].id" contains "{{other_id}}"

GET {{base_url}}/api/users/patients/{{patient_id}}
Authorization: Bearer {{doctor_token}}
HTTP 200
[Asserts]
jsonpath "$.user.id" == "{{patient_id}}"
jsonpath "$.vitals[0].id" == "{{vital_id}}"

DELETE {{base_url}}/api/health-updates/{{vital_id}}
Authorization: Bearer {{patient_token}}
HTTP 204

GET {{base_url}}/api/health-updates/{{vital_id}}
Authorization: Bearer {{patient_token}}
HTTP 404

# 11 · Inbox. Kirim ke ID User dokter, baca pesan sebagai penerima, lalu periksa badge.

POST {{base_url}}/api/messages
Authorization: Bearer {{doctor_token}}
{"receiverId":"{{patient_id}}","content":"Pesan HURL-{{run_id}}"}
HTTP 200
[Captures]
message_id: jsonpath "$.id"
[Asserts]
jsonpath "$.isRead" == false

GET {{base_url}}/api/messages/conversations?q={{run_id}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].peerId" == "{{doctor_user_id}}"
jsonpath "$[0].unreadCount" == 1
jsonpath "$[0].latestMessage.id" == "{{message_id}}"

GET {{base_url}}/api/messages?peerId={{doctor_user_id}}&limit=10&page=1
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].id" == "{{message_id}}"
jsonpath "$[0].isRead" == false

PUT {{base_url}}/api/messages/{{message_id}}/read
Authorization: Bearer {{patient_token}}
HTTP 200

GET {{base_url}}/api/messages/conversations?q={{run_id}}
Authorization: Bearer {{patient_token}}
HTTP 200
[Asserts]
jsonpath "$[0].unreadCount" == 0

DELETE {{base_url}}/api/messages/{{message_id}}
Authorization: Bearer {{doctor_token}}
HTTP 204

# 12 · Upload publik lama untuk avatar. File sintetis diuji melalui Nginx.

POST {{base_url}}/api/upload
Authorization: Bearer {{patient_token}}
[Multipart]
file: file,fixtures/sample.pdf; application/pdf
HTTP 200
[Captures]
public_file: jsonpath "$.url"
[Asserts]
jsonpath "$.url" startsWith "/uploads/"

GET {{base_url}}{{public_file}}
HTTP 200
[Asserts]
bytes startsWith hex,255044462d;

# 13 · Tutup alur. Hapus jadwal tambahan agar slot utama masih tersedia untuk tes paralel.

POST {{base_url}}/api/schedules
Authorization: Bearer {{doctor_token}}
{"dayOfWeek":"{{visit_weekday}}","startTime":"14:00","endTime":"15:00","isAvailable":false}
HTTP 200
[Captures]
temporary_schedule_id: jsonpath "$.id"

DELETE {{base_url}}/api/schedules/{{temporary_schedule_id}}
Authorization: Bearer {{doctor_token}}
HTTP 204

# Tes penggantian password hanya mengubah akun pasien dummy.

POST {{base_url}}/api/auth/change-password
Authorization: Bearer {{patient_token}}
{"currentPassword":"hurl-fixture-{{run_id}}","newPassword":"hurl-fixture-{{run_id}}-updated"}
HTTP 200
[Asserts]
jsonpath "$.success" == true

POST {{base_url}}/api/auth/login
{"email":"hurl-patient-{{run_id}}@example.test","password":"hurl-fixture-{{run_id}}"}
HTTP 401

POST {{base_url}}/api/auth/login
[Multipart]
email: hurl-patient-{{run_id}}@example.test
password: hurl-fixture-{{run_id}}-updated
HTTP 200
[Captures]
patient_token: jsonpath "$.token"
[Asserts]
jsonpath "$.token" exists
jsonpath "$.user.passwordHash" not exists

POST {{base_url}}/api/auth/logout
Authorization: Bearer {{patient_token}}
HTTP 200
