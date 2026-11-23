# 01 · Admin. CRUD hanya memakai akun dummy yang dibuat oleh skenario ini.

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

POST {{base_url}}/api/users
Authorization: Bearer {{admin_token}}
{"name":"HURL-{{run_id}} admin fixture","email":"hurl-admin-fixture-{{run_id}}@example.test","password":"hurl-fixture-{{run_id}}","role":"patient"}
HTTP 200
[Captures]
admin_fixture_id: jsonpath "$.id"
[Asserts]
jsonpath "$.role" == "patient"

GET {{base_url}}/api/users
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$[*].id" contains "{{admin_fixture_id}}"

GET {{base_url}}/api/users/{{admin_fixture_id}}
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.email" == "hurl-admin-fixture-{{run_id}}@example.test"
jsonpath "$.passwordHash" not exists

PUT {{base_url}}/api/users/{{admin_fixture_id}}
Authorization: Bearer {{admin_token}}
{"city":"Bandung"}
HTTP 200
[Asserts]
jsonpath "$.city" == "Bandung"

DELETE {{base_url}}/api/users/{{admin_fixture_id}}
Authorization: Bearer {{admin_token}}
HTTP 204

GET {{base_url}}/api/users/{{admin_fixture_id}}
Authorization: Bearer {{admin_token}}
HTTP 404

# 02 · Admin dokter. Dokter sementara dapat diubah dan dihapus setelah kontraknya diperiksa.

POST {{base_url}}/api/doctors
Authorization: Bearer {{admin_token}}
{
  "name": "HURL-{{run_id}} admin-doctor",
  "email": "hurl-admin-doctor-{{run_id}}@example.test",
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
admin_doctor_id: jsonpath "$.id"
admin_doctor_user_id: jsonpath "$.user.id"

PUT {{base_url}}/api/doctors/{{admin_doctor_id}}
Authorization: Bearer {{admin_token}}
{
  "name": "HURL-{{run_id}} admin-doctor",
  "email": "hurl-admin-doctor-{{run_id}}@example.test",
  "password": "hurl-fixture-{{run_id}}",
  "phone": "0000000000",
  "specialty": "Cardiology",
  "status": "busy",
  "experience": 14,
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
[Asserts]
jsonpath "$.status" == "busy"
jsonpath "$.experience" == 14

GET {{base_url}}/api/doctors/{{admin_doctor_id}}
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.userId" == "{{admin_doctor_user_id}}"
jsonpath "$.experience" == 14

DELETE {{base_url}}/api/doctors/{{admin_doctor_id}}
Authorization: Bearer {{admin_token}}
HTTP 204

DELETE {{base_url}}/api/users/{{admin_doctor_user_id}}
Authorization: Bearer {{admin_token}}
HTTP 204

# 03 · Analitik. Dataset lain bisa ada, jadi cek bentuk respons dan nilai yang tidak negatif.

GET {{base_url}}/api/analytics/dashboard
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.totalPatients" >= 0
jsonpath "$.totalDoctors" >= 0
jsonpath "$.totalAppointments" >= 0

GET {{base_url}}/api/analytics/appointments
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.total" >= 0
jsonpath "$.cancelled" >= 0

GET {{base_url}}/api/analytics/doctors
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$" isList

GET {{base_url}}/api/analytics/health
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$" isList

# 04 · Peringatan sistem. Hanya alert HURL yang diubah dari aktif ke selesai.

POST {{base_url}}/api/system-alerts
Authorization: Bearer {{admin_token}}
{"type":"maintenance","title":"HURL-{{run_id}} alert","message":"Peringatan sintetis"}
HTTP 200
[Captures]
alert_id: jsonpath "$.id"
[Asserts]
jsonpath "$.status" == "active"

GET {{base_url}}/api/system-alerts
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$[*].id" contains "{{alert_id}}"

POST {{base_url}}/api/system-alerts/{{alert_id}}/resolve
Authorization: Bearer {{admin_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "resolved"
