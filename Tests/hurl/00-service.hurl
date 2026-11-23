# Smoke test melalui port Nginx Docker. Header membuktikan respons lewat proxy.
GET {{base_url}}/health
HTTP 200
[Asserts]
header "X-Served-By" exists
jsonpath "$.status" == "healthy"
jsonpath "$.node" matches "^vapor-node-[12]$"
jsonpath "$.timestamp" isIsoDate

# Kontrak OpenAPI harus memuat route yang dipakai aplikasi iOS.
GET {{base_url}}/swagger.json
HTTP 200
[Asserts]
jsonpath "$.info.title" == "RS Permata Sehat API"
jsonpath "$.paths['/api/appointments'].post" exists
jsonpath "$.paths['/api/documents'].post" exists

GET {{base_url}}/api-docs
HTTP 200
[Asserts]
body contains "SwaggerUIBundle"

# Route pasien memerlukan JWT meski daftar dokter sempat ditandai public di dokumen lama.
GET {{base_url}}/api/doctors
HTTP 401

GET {{base_url}}/api/documents
HTTP 401
