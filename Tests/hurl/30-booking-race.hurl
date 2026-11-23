# Runner menjalankan file ini di dua worker. Keduanya memakai slot dummy yang sama.
POST {{base_url}}/api/auth/login
{"email":"hurl-other-{{run_id}}@example.test","password":"hurl-fixture-{{run_id}}"}
HTTP 200
[Captures]
race_token: jsonpath "$.token"

GET {{base_url}}/api/doctors?q={{run_id}}
Authorization: Bearer {{race_token}}
HTTP 200
[Captures]
race_doctor_id: jsonpath "$[0].id"
[Asserts]
jsonpath "$" count == 1

# Kedua status dinilai bersama oleh run.sh karena worker mana pun bisa menang.
POST {{base_url}}/api/appointments
Authorization: Bearer {{race_token}}
{"doctorId":"{{race_doctor_id}}","date":"{{visit_date}}","time":"10:00","reason":"HURL parallel {{run_id}}"}
