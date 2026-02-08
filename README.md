```markdown
# BeRumahsakit API 🏥

A robust Hospital Management System API built with **Swift Vapor**.
It features Role-Based Access Control (RBAC) for **Admins**, **Doctors**, and **Patients**.

---

## 🏆 Project Summary & Status

> **Current Status:** 🚀 **Production Ready (v1.0)** > **Completion:** 95% Complete

This API serves as the backend for a comprehensive Digital Hospital System. It includes:

| Feature | Status | Description |
| :--- | :---: | :--- |
| **Authentication** | ✅ | JWT-based Auth, Password Management |
| **RBAC** | ✅ | Strict separation of Patient, Doctor, and Admin roles |
| **Appointments** | ✅ | Booking, Approving, Rejecting, and Cancelling |
| **Medical Records** | ✅ | Digital diagnosis, prescriptions, and history |
| **Scheduling** | ✅ | Doctor availability management |
| **Messaging** | ✅ | Internal chat system between users |
| **Analytics** | ✅ | Dashboards for health trends and doctor performance |
| **File System** | ✅ | Uploading profile pictures and documents |

---

## 🚀 Getting Started

### Prerequisites
- Swift 5.9+
- Docker (for MySQL database)

### Installation
1. **Start Database**
   ```bash
   docker-compose up -d db

```

2. **Run Migrations** (Fresh install)
```bash
./migrate-fresh.sh

```


3. **Run Server**
```bash
swift run

```



The API will start at: `http://localhost:8080`

---

## 📚 API Documentation

### Base URL

```
http://localhost:8080

```

### Authentication Header

Most endpoints require a **Bearer Token**:

```http
Authorization: Bearer <YOUR_JWT_TOKEN>

```

---

## 🔓 Public Endpoints

### 1. Register (Patients Only)

`POST /api/auth/register`

**Request:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "role": "patient"
}

```

**Response:**

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "patient",
  "createdAt": "2026-02-08T10:00:00Z"
}

```

### 2. Login

`POST /api/auth/login`

**Request:**

```json
{
  "email": "john@example.com",
  "password": "securePassword123"
}

```

**Response:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "patient"
  }
}

```

### 3. List Doctors (Public)

`GET /api/doctors`

**Response:**

```json
[
  {
    "id": "doc-uuid-1",
    "name": "Dr. Stephen Strange",
    "specialty": "Neurosurgery",
    "status": "active",
    "rating": 4.9,
    "experience": 15,
    "education": "MD, PhD from Columbia University",
    "bio": "Expert in neurological disorders."
  }
]

```

---

## 🔒 User Profile & Management

### Get My Profile

`GET /api/users/me`

**Response:**

```json
{
  "id": "user-uuid",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "patient",
  "phone": "0812345678",
  "city": "Jakarta"
}

```

### Update Profile

`PUT /api/users/me`

**Request:**

```json
{
  "phone": "089999999",
  "address": "Jl. Sudirman",
  "city": "Jakarta",
  "emergencyContact": "Jane Doe",
  "emergencyPhone": "081111111"
}

```

### Change Password

`POST /api/auth/change-password`

**Request:**

```json
{
  "currentPassword": "oldPass",
  "newPassword": "newPass"
}

```

**Response:** `200 OK`

---

## 📅 Appointments

### List Appointments

`GET /api/appointments`

> Filters: `?status=pending`

**Response:**

```json
[
  {
    "id": "appt-uuid",
    "date": "2026-02-10",
    "time": "09:00",
    "status": "pending",
    "reason": "Headache",
    "doctor": { "name": "Dr. Strange", "specialty": "Neurosurgery" },
    "patient": { "name": "John Doe" }
  }
]

```

### Book Appointment

`POST /api/appointments`

**Request:**

```json
{
  "doctorId": "doc-uuid",
  "date": "2026-02-10",
  "time": "09:00",
  "reason": "Routine Checkup",
  "complaints": "Mild fever"
}

```

**Response:**

```json
{
  "id": "appt-uuid",
  "status": "pending",
  "date": "2026-02-10",
  "time": "09:00"
}

```

### Cancel Appointment

`DELETE /api/appointments/:id`
**Response:** `204 No Content`

### Appointments Today (Doctor/Admin)

`GET /api/appointments/today`

**Response:** (Same list as above, filtered for today)

---

## 📋 Medical Records

### List Records

`GET /api/medical-records`

> Patients see their own. Doctors see all/filtered.

**Response:**

```json
[
  {
    "id": "rec-uuid",
    "diagnosis": "Seasonal Flu",
    "symptoms": "Fever, Cough",
    "treatment": "Rest, Hydration",
    "prescription": "Paracetamol 500mg",
    "createdAt": "2026-02-08T14:00:00Z",
    "doctor": { "name": "Dr. Strange" },
    "appointment": { "date": "2026-02-08" }
  }
]

```

### Get Patient History (Doctor)

`GET /api/medical-records/patient/:id`

**Response:** Returns list of records for that specific patient.

### Create Record (Doctor)

`POST /api/medical-records`

> Note: This automatically marks the appointment as "completed".

**Request:**

```json
{
  "appointmentId": "appt-uuid",
  "diagnosis": "Hypertension",
  "symptoms": "Dizziness",
  "treatment": "Lifestyle changes",
  "prescription": "Amlodipine 5mg",
  "notes": "Follow up in 2 weeks",
  "vitalSigns": {
    "bloodPressure": "140/90",
    "weight": "80",
    "temperature": "36.5"
  }
}

```

**Response:** Returns the created `MedicalRecord` object.

---

## 💬 Messaging

### List Messages

`GET /api/messages`

**Response:**

```json
[
  {
    "id": "msg-uuid",
    "senderName": "Dr. Strange",
    "receiverId": "my-uuid",
    "content": "Please remember to fast before the blood test.",
    "isRead": false,
    "createdAt": "2026-02-08T10:30:00Z"
  }
]

```

### Send Message

`POST /api/messages`

**Request:**

```json
{
  "receiverId": "target-user-uuid",
  "content": "Thank you, Doctor. I will."
}

```

### Mark Read

`PUT /api/messages/:id/read`
**Response:** `200 OK`

---

## 📈 Health Tracker

### Log Vitals

`POST /api/health-updates`

**Request:**

```json
{
  "date": "2026-02-08",
  "weight": 70.5,
  "bloodPressure": "120/80",
  "heartRate": 72,
  "mood": "Happy",
  "notes": "Morning jog completed"
}

```

### List Vitals

`GET /api/health-updates`

**Response:**

```json
[
  {
    "id": "health-uuid",
    "date": "2026-02-08",
    "bloodPressure": "120/80",
    "mood": "Happy"
  }
]

```

---

## 📂 File System

### Upload File

`POST /api/upload`

> Content-Type: `multipart/form-data`

**Request:** Form field `file` containing the image/pdf.

**Response:**

```json
{
  "filename": "A1B2C3D4.jpg",
  "url": "/uploads/A1B2C3D4.jpg"
}

```

---

## 🩺 Doctor Self-Service

### Get My Profile

`GET /api/doctors/me`

**Response:**

```json
{
  "id": "doc-uuid",
  "name": "Dr. Strange",
  "specialty": "Neurosurgery",
  "status": "active",
  "totalPatients": 120,
  "rating": 5.0
}

```

### Update Availability (Schedule)

`POST /api/schedules`

**Request:**

```json
{
  "dayOfWeek": "Monday",
  "startTime": "08:00",
  "endTime": "16:00",
  "isAvailable": true
}

```

**Response:**

```json
{
  "id": "sched-uuid",
  "dayOfWeek": "Monday",
  "startTime": "08:00",
  "endTime": "16:00"
}

```

---

## 👮 Admin Dashboard & Analytics

### System Dashboard

`GET /api/analytics/dashboard`

**Response:**

```json
{
  "totalPatients": 150,
  "totalDoctors": 12,
  "totalAppointments": 340,
  "revenue": 0
}

```

### Doctor Performance

`GET /api/analytics/doctors`

**Response:**

```json
[
  {
    "name": "Dr. Strange",
    "appointmentCount": 45,
    "rating": 5.0
  }
]

```

### Health Trends

`GET /api/analytics/health`

**Response:**

```json
[
  { "diagnosis": "Flu", "count": 25 },
  { "diagnosis": "Gastritis", "count": 10 }
]

```

### System Alerts

`GET /api/system-alerts`

**Response:**

```json
[
  {
    "id": "alert-uuid",
    "type": "critical",
    "title": "High CPU Usage",
    "status": "active"
  }
]

```

---

## 🛠 Tech Stack

* **Language:** Swift 5.9
* **Framework:** Vapor 4
* **Database:** MySQL 8.0
* **ORM:** Fluent
* **Auth:** JWT (JSON Web Tokens)
* **Container:** Docker

```

```