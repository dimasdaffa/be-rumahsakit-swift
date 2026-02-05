# BeRumahsakit API 🏥

A robust Hospital Management System API built with **Swift Vapor**.
It features Role-Based Access Control (RBAC) for **Admins**, **Doctors**, and **Patients**.

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

### Authentication

Most endpoints require a **Bearer Token**. Include it in the header:

```http
Authorization: Bearer <YOUR_JWT_TOKEN>

```

---

## 🔓 Public Endpoints

### 1. Authentication

#### Register (Patients Only)

`POST /api/auth/register`

> Doctors and Admins must be created by an Admin.

**Request:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "role": "patient"
}

```

#### Login

`POST /api/auth/login`

**Response:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "patient"
  }
}

```

### 2. Doctors (Public Directory)

#### List All Doctors

`GET /api/doctors`

> Returns a safe public profile (excludes sensitive user data).

**Response:**

```json
[
  {
    "id": "uuid",
    "name": "Dr. Stephen Strange",
    "specialty": "Neurosurgery",
    "status": "active",
    "rating": 5.0,
    "experience": 12
  }
]

```

---

## 🔒 Protected Endpoints (All Users)

### 1. User Profile

#### Get My Profile

`GET /api/users/me`

#### Update My Profile

`PUT /api/users/me`

**Request:**

```json
{
  "phone": "+62812345678",
  "address": "Jl. Sudirman No. 1",
  "city": "Jakarta",
  "emergencyContact": "Jane Doe",
  "emergencyPhone": "+62899999"
}

```

#### Change Password

`POST /api/auth/change-password`

**Request:**

```json
{
  "currentPassword": "oldPass",
  "newPassword": "newPass"
}

```

### 2. Appointments

#### List Appointments

`GET /api/appointments`

* **Patient:** Sees own appointments.
* **Doctor:** Sees appointments assigned to them.
* **Admin:** Sees all appointments.

#### Book Appointment

`POST /api/appointments`

**Request:**

```json
{
  "doctorId": "uuid-of-doctor",
  "date": "2026-02-01",
  "time": "09:00",
  "reason": "General Checkup",
  "complaints": "Dizzy when standing"
}

```

#### View Appointment Detail

`GET /api/appointments/:id`

### 3. Messaging

#### List Messages

`GET /api/messages`

> Returns inbox and sent messages combined.

#### Send Message

`POST /api/messages`

**Request:**

```json
{
  "receiverId": "uuid-of-receiver",
  "content": "Hello, I have a question about my prescription."
}

```

#### Mark as Read

`PUT /api/messages/:id/read`

### 4. Health Tracker

#### Log Health Update

`POST /api/health-updates`

**Request:**

```json
{
  "date": "2026-02-01",
  "weight": 70.5,
  "bloodPressure": "120/80",
  "heartRate": 72,
  "mood": "Happy",
  "notes": "Feeling better today"
}

```

#### List Health Updates

`GET /api/health-updates`

### 5. Schedules

#### List Doctor Schedules

`GET /api/schedules`

> Returns all doctor schedules. Filter by doctor using query param.

**Query Parameters:**
- `doctorId` (optional): Filter schedules by doctor UUID

**Response:**

```json
[
  {
    "id": "uuid",
    "doctor": { "id": "doctor-uuid" },
    "dayOfWeek": "Monday",
    "startTime": "09:00",
    "endTime": "17:00",
    "isAvailable": true,
    "createdAt": "2026-02-05T14:36:13Z"
  }
]
```

---

## 🩺 Doctor & Admin Only

### 1. Medical Records

#### Create Medical Record

`POST /api/medical-records`

> Automatically marks the appointment as "completed".

**Request:**

```json
{
  "appointmentId": "uuid-of-appointment",
  "diagnosis": "Flu",
  "symptoms": "Fever, Cough",
  "treatment": "Rest",
  "prescription": "Paracetamol",
  "notes": "Drink water",
  "followUpRequired": true,
  "followUpDate": "2026-02-10",
  "vitalSigns": {
    "bloodPressure": "120/80",
    "weight": "70"
  }
}

```

### 2. Clinical Notes (Internal)

#### Create Clinical Note

`POST /api/clinical-notes`

**Request:**

```json
{
  "patientId": "uuid-of-patient",
  "appointmentId": "uuid-of-appointment",
  "diagnosis": "Suspected Typhoid",
  "treatment": "Further lab tests required",
  "notes": "Patient looks pale",
  "status": "draft"
}

```

### 3. Patient Management

#### List All Patients

`GET /api/users/patients`

#### Get Patient Detail

`GET /api/users/patients/:id`

---

## 👮 Admin Only

### 1. User Management

* `POST /api/users` - Create any user (Admin, Doctor, Patient).
* `GET /api/users` - List all system users.
* `DELETE /api/users/:id` - Delete a user.

### 2. Doctor Management

* `POST /api/doctors` - Create a Doctor (Profile + User Account).
* `PUT /api/doctors/:id` - Update Doctor.
* `DELETE /api/doctors/:id` - Delete Doctor.

**Create Doctor Request:**

```json
{
  "name": "Dr. Strange",
  "email": "strange@hospital.com",
  "password": "optionalPassword",
  "phone": "08123456789",
  "specialty": "Magic",
  "status": "active",
  "experience": 10,
  "totalPatients": 0,
  "rating": 5.0
}

```

### 3. Appointment Actions

* `PUT /api/appointments/:id/approve`
* `PUT /api/appointments/:id/reject`

### 4. Analytics

* `GET /api/analytics/dashboard`

---

## 🗓 Doctor Only

### Schedule Management

#### Create Schedule

`POST /api/schedules`

**Request:**

```json
{
  "dayOfWeek": "Monday",
  "startTime": "09:00",
  "endTime": "17:00",
  "isAvailable": true
}
```

**Response:**

```json
{
  "id": "uuid",
  "doctor": { "id": "doctor-uuid" },
  "dayOfWeek": "Monday",
  "startTime": "09:00",
  "endTime": "17:00",
  "isAvailable": true,
  "createdAt": "2026-02-05T14:36:13Z"
}
```

#### Update Schedule

`PUT /api/schedules/:id`

**Request:**

```json
{
  "dayOfWeek": "Tuesday",
  "startTime": "10:00",
  "endTime": "18:00",
  "isAvailable": false
}
```

#### Delete Schedule

`DELETE /api/schedules/:id`

> Returns `204 No Content` on success.

---

## 🛠 Tech Stack

* **Language:** Swift 5.9
* **Framework:** Vapor 4
* **Database:** MySQL 8.0
* **ORM:** Fluent
* **Auth:** JWT (JSON Web Tokens)
* **Container:** Docker

```