# 📚 Complete API Specification - RS Permata Sehat

> **Hospital Management System - Digital Control Schedule**  
> Last Updated: January 9, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [API Status Legend](#api-status-legend)
4. [Public Endpoints](#-public-endpoints)
5. [User Management](#-user-management)
6. [Appointments](#-appointments)
7. [Medical Records](#-medical-records)
8. [Clinical Notes](#-clinical-notes)
9. [Health Updates](#-health-updates)
10. [Doctor Management](#-doctor-management)
11. [Schedules](#-schedules)
12. [Messaging](#-messaging)
13. [File Upload](#-file-upload)
14. [Analytics](#-analytics)
15. [System Alerts](#-system-alerts)
16. [Data Models](#-data-models)
17. [Error Handling](#-error-handling)

---

## Overview

### Base URL

```
Development: http://localhost:8080
Production: https://api.rspermatasehat.com
```

### Interactive Documentation

- **Swagger UI**: `GET /api-docs`
- **OpenAPI JSON**: `GET /swagger.json`

### Response Format

```json
{
  "success": true,
  "data": {},
  "message": "Success message",
  "timestamp": "2026-01-09T10:00:00Z"
}
```

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description",
    "details": {}
  },
  "timestamp": "2026-01-09T10:00:00Z"
}
```

---

## Authentication

- **Type**: JWT (JSON Web Token)
- **Header**: `Authorization: Bearer <token>`
- **Token Expiry**: 24 hours

---

## API Status Legend

| Status             | Meaning                                   |
| ------------------ | ----------------------------------------- |
| ✅ **IMPLEMENTED** | API is ready and working                  |
| ⚠️ **NEEDED**      | API must be implemented (critical)        |
| 🔶 **RECOMMENDED** | API should be implemented (high priority) |
| 💡 **OPTIONAL**    | Nice to have (low priority)               |

---

## 🔓 Public Endpoints

### Authentication

#### ✅ Register New User

```http
POST /api/auth/register
```

**Request Body:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "role": "patient"
}
```

| Field    | Type   | Required | Description                     |
| -------- | ------ | -------- | ------------------------------- |
| name     | string | ✓        | Full name                       |
| email    | string | ✓        | Valid email address             |
| password | string | ✓        | Min 8 characters                |
| role     | string | ✓        | `admin`, `doctor`, or `patient` |

**Response:** `201 Created`

```json
{
  "id": "uuid",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "patient",
  "createdAt": "2026-01-09T10:00:00Z"
}
```

---

#### ✅ Login

```http
POST /api/auth/login
```

**Request Body:**

```json
{
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Response:** `200 OK`

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "patient"
  },
  "expiresAt": "2026-01-10T10:00:00Z"
}
```

---

#### ⚠️ Logout

```http
POST /api/auth/logout
```

**Headers:** `Authorization: Bearer <token>`  
**Response:** `200 OK`

```json
{
  "message": "Logged out successfully"
}
```

---

#### ✅ Change Password

```http
POST /api/auth/change-password
```

**Headers:** `Authorization: Bearer <token>`  
**Request Body:**

```json
{
  "currentPassword": "oldPassword123",
  "newPassword": "newSecurePassword456"
}
```

**Response:** `200 OK`

---

#### 💡 Forgot Password

```http
POST /api/auth/forgot-password
```

**Request Body:**

```json
{
  "email": "john@example.com"
}
```

**Response:** `200 OK` - Sends reset email

---

#### 💡 Reset Password

```http
POST /api/auth/reset-password
```

**Request Body:**

```json
{
  "token": "reset-token-from-email",
  "newPassword": "newSecurePassword456"
}
```

---

#### 🔶 Verify Token

```http
GET /api/auth/verify
```

**Headers:** `Authorization: Bearer <token>`  
**Response:** `200 OK` if valid, `401 Unauthorized` if invalid

---

## 👤 User Management

> **Access:** Admin only (except `/me` endpoints)

#### ✅ Get Current User

```http
GET /api/users/me
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** All authenticated users  
**Response:**

```json
{
  "id": "uuid",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "patient",
  "phone": "+62812345678",
  "dateOfBirth": "1990-01-15",
  "gender": "male",
  "address": "Jl. Sudirman No. 123",
  "city": "Semarang",
  "province": "Jawa Tengah",
  "postalCode": "50123",
  "emergencyContact": "Jane Doe",
  "emergencyPhone": "+62887654321",
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-09T10:00:00Z"
}
```

---

#### ✅ Update Current User Profile

```http
PUT /api/users/me
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** All authenticated users  
**Request Body:**

```json
{
  "name": "John Doe Updated",
  "phone": "+62812345678",
  "dateOfBirth": "1990-01-15",
  "gender": "male",
  "address": "Jl. Sudirman No. 123",
  "city": "Semarang",
  "province": "Jawa Tengah",
  "postalCode": "50123",
  "emergencyContact": "Jane Doe",
  "emergencyPhone": "+62887654321"
}
```

---

#### ✅ List All Users

```http
GET /api/users
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Admin only  
**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| role | string | Filter by `admin`, `doctor`, `patient` |
| status | string | Filter by `active`, `inactive` |
| search | string | Search by name or email |
| page | int | Page number (default: 1) |
| limit | int | Items per page (default: 20) |

**Response:**

```json
{
  "data": [...],
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalItems": 100,
    "itemsPerPage": 20
  }
}
```

---

#### ✅ Get User by ID

```http
GET /api/users/:id
```

**Access:** Admin only

---

#### ✅ Create User

```http
POST /api/users
```

**Access:** Admin only  
**Request Body:**

```json
{
  "name": "New User",
  "email": "newuser@example.com",
  "password": "password123",
  "role": "patient",
  "status": "active"
}
```

---

#### ✅ Update User

```http
PUT /api/users/:id
```

**Access:** Admin only

---

#### ✅ Delete User

```http
DELETE /api/users/:id
```

**Access:** Admin only  
**Response:** `204 No Content`

---

#### ✅ List All Patients

```http
GET /api/users/patients
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctors and Admins  
**Description:** Returns users with role `patient`

---

#### ✅ Get Patient Details

```http
GET /api/users/patients/:id
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctors and Admins  
**Response:** Complete patient profile with medical history summary

---

## 📅 Appointments

#### ✅ List Appointments

```http
GET /api/appointments
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** All authenticated users

- **Patients:** See only their own appointments
- **Doctors:** See appointments assigned to them
- **Admins:** See all appointments

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| status | string | `pending`, `approved`, `rejected`, `completed` |
| date | string | Filter by date (YYYY-MM-DD) |
| doctorId | string | Filter by doctor UUID |
| patientId | string | Filter by patient UUID |

---

#### ✅ Book New Appointment

```http
POST /api/appointments
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** All authenticated users  
**Request Body:**

```json
{
  "doctorId": "uuid-of-doctor",
  "date": "2026-01-15",
  "time": "09:00",
  "reason": "Regular checkup",
  "complaints": "Headache and fever"
}
```

**Response:** `201 Created` - Appointment with status `pending`

---

#### ✅ View Single Appointment

```http
GET /api/appointments/:id
```

**Access:** Owner of appointment, assigned Doctor, or Admin

---

#### ⚠️ Update Appointment

```http
PUT /api/appointments/:id
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Owner (if pending) or Admin  
**Request Body:**

```json
{
  "date": "2026-01-16",
  "time": "10:00",
  "reason": "Updated reason"
}
```

---

#### ⚠️ Cancel/Delete Appointment

```http
DELETE /api/appointments/:id
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Owner (if pending) or Admin  
**Response:** `204 No Content`

---

#### ✅ Approve Appointment (Admin)

```http
PUT /api/appointments/:id/approve
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Admin only  
**Response:** Updated appointment with status `approved`

---

#### ✅ Reject Appointment (Admin)

```http
PUT /api/appointments/:id/reject
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Admin only  
**Request Body (optional):**

```json
{
  "rejectionReason": "Doctor not available on this date"
}
```

---

#### 🔶 Complete Appointment

```http
PUT /api/appointments/:id/complete
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctor or Admin  
**Description:** Marks appointment as completed

---

#### 🔶 Get Today's Appointments

```http
GET /api/appointments/today
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctors and Admins  
**Description:** Returns appointments for current date

---

## 📋 Medical Records

#### ✅ List Medical Records

```http
GET /api/medical-records
```

**Headers:** `Authorization: Bearer <token>`  
**Access:**

- **Patients:** See only their own records
- **Doctors/Admins:** See all records

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| patientId | string | Filter by patient |
| doctorId | string | Filter by doctor |
| dateFrom | string | Start date |
| dateTo | string | End date |

---

#### ✅ Create Medical Record

```http
POST /api/medical-records
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctors and Admins  
**Request Body:**

```json
{
  "appointmentId": "uuid-of-appointment",
  "patientId": "uuid-of-patient",
  "diagnosis": "Common cold",
  "symptoms": "Fever, cough, runny nose",
  "treatment": "Rest and hydration",
  "prescription": "Paracetamol 500mg, 3x daily",
  "notes": "Follow up in 1 week if symptoms persist",
  "followUpRequired": true,
  "followUpDate": "2026-01-16",
  "vitalSigns": {
    "bloodPressure": "120/80",
    "heartRate": "72",
    "temperature": "37.5",
    "weight": "70"
  }
}
```

> **Note:** Creating a medical record automatically marks the related appointment as `completed`

---

#### ✅ View Medical Record Details

```http
GET /api/medical-records/:id
```

**Access:** Record owner (patient), assigned Doctor, or Admin

---

#### ⚠️ Update Medical Record

```http
PUT /api/medical-records/:id
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Record creator (Doctor) or Admin

---

#### ⚠️ Delete Medical Record

```http
DELETE /api/medical-records/:id
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Admin only  
**Response:** `204 No Content`

---

#### ⚠️ Get Patient's Medical Records

```http
GET /api/medical-records/patient/:patientId
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Patient (own records), Doctors, Admin

---

## 📝 Clinical Notes

> **Critical:** Your frontend has a clinical notes system that needs backend support

#### ⚠️ List Clinical Notes

```http
GET /api/clinical-notes
```

**Headers:** `Authorization: Bearer <token>`  
**Access:**

- **Doctors:** See notes they created
- **Admins:** See all notes

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| doctorId | string | Filter by doctor |
| patientId | string | Filter by patient |
| appointmentId | string | Filter by appointment |

---

#### ✅ Create Clinical Note

```http
POST /api/clinical-notes
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctors only  
**Request Body:**

```json
{
  "patientId": "uuid-of-patient",
  "appointmentId": "uuid-of-appointment",
  "diagnosis": "Hypertension Grade 1",
  "treatment": "Lifestyle modification, medication if needed",
  "notes": "Patient advised to reduce salt intake",
  "followUp": "2026-02-09",
  "status": "completed"
}
```

---

#### ⚠️ Get Clinical Note

```http
GET /api/clinical-notes/:id
```

---

#### ⚠️ Update Clinical Note

```http
PUT /api/clinical-notes/:id
```

**Access:** Note creator or Admin

---

#### ⚠️ Delete Clinical Note

```http
DELETE /api/clinical-notes/:id
```

**Access:** Admin only

---

## 💊 Health Updates

> **Purpose:** Track patient health progress over time

#### ✅ List Health Updates

```http
GET /api/health-updates
```

**Headers:** `Authorization: Bearer <token>`  
**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| patientId | string | Filter by patient |
| doctorId | string | Filter by doctor |
| status | string | `draft`, `completed` |

---

#### ✅ Create Health Update

```http
POST /api/health-updates
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctors only  
**Request Body:**

```json
{
  "patientId": "uuid-of-patient",
  "patientName": "John Doe",
  "diagnosis": "Diabetes Type 2 - Controlled",
  "treatment": "Continue metformin, diet control",
  "date": "2026-01-09",
  "notes": "HbA1c improved from 8.2 to 7.1",
  "followUpRequired": true,
  "followUpDate": "2026-02-09",
  "status": "completed"
}
```

---

#### ⚠️ Get Patient Health Updates

```http
GET /api/health-updates/patient/:patientId
```

**Access:** Patient (own), Doctor who treated, Admin

---

## 👨‍⚕️ Doctor Management

> **Access:** Admin only (except `/me` endpoints)

#### ✅ List All Doctors

```http
GET /api/doctors
```

**Response:**

```json
[
  {
    "id": "uuid",
    "name": "Dr. Jane Smith",
    "email": "jane.smith@hospital.com",
    "phone": "+62812345678",
    "specialty": "Cardiology",
    "status": "active",
    "license": "STR-12345",
    "experience": 10,
    "education": "MD from University of Indonesia",
    "bio": "Specialist in heart diseases",
    "joinDate": "2020-01-15",
    "totalPatients": 150,
    "rating": 4.9
  }
]
```

---

#### ✅ Create Doctor

```http
POST /api/doctors
```

**Access:** Admin only  
**Request Body:**

```json
{
  "name": "Dr. Jane Smith",
  "email": "jane.smith@hospital.com",
  "password": "securePassword123",
  "phone": "+62812345678",
  "specialty": "Cardiology",
  "status": "active",
  "license": "STR-12345",
  "experience": 10,
  "education": "MD from University of Indonesia",
  "bio": "Specialist in heart diseases",
  "joinDate": "2020-01-15"
}
```

---

#### ✅ Get Doctor Details

```http
GET /api/doctors/:id
```

---

#### ✅ Update Doctor

```http
PUT /api/doctors/:id
```

**Access:** Admin only

---

#### ✅ Delete Doctor

```http
DELETE /api/doctors/:id
```

**Access:** Admin only  
**Response:** `204 No Content`

---

#### ⚠️ Get Current Doctor Profile

```http
GET /api/doctors/me
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctor only  
**Description:** Doctor can view their own profile

---

#### ⚠️ Update Current Doctor Profile

```http
PUT /api/doctors/me
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctor only  
**Request Body:**

```json
{
  "phone": "+62812345678",
  "bio": "Updated bio",
  "education": "Updated education info"
}
```

---

#### ⚠️ Update Doctor Credentials

```http
PUT /api/doctors/me/credentials
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** Doctor only  
**Request Body:**

```json
{
  "currentPassword": "oldPassword",
  "newPassword": "newSecurePassword"
}
```

---

#### 🔶 Get Doctor's Schedules

```http
GET /api/doctors/:id/schedules
```

**Description:** Get all schedules for a specific doctor

---

#### 🔶 Get Doctor's Patients

```http
GET /api/doctors/:id/patients
```

**Access:** Doctor (own) or Admin  
**Description:** List patients who had appointments with this doctor

---

## 📆 Schedules

#### ✅ List Schedules

```http
GET /api/schedules
```

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| doctorId | string | Filter by doctor UUID |
| date | string | Filter by date |
| available | boolean | Only show available slots |

---

#### ✅ Generate Schedule Slots

```http
POST /api/schedules/generate
```

**Access:** Admin only  
**Request Body:**

```json
{
  "doctorId": "uuid-of-doctor",
  "date": "2026-01-30"
}
```

**Description:** Automatically creates time slots: 09:00, 10:00, 11:00, 13:00, 14:00, 15:00

---

#### ✅ Create Single Schedule Slot

```http
POST /api/schedules
```

**Access:** Admin only  
**Request Body:**

```json
{
  "doctorId": "uuid-of-doctor",
  "date": "2026-01-30",
  "time": "16:00",
  "isAvailable": true
}
```

---

#### ✅ Update Schedule

```http
PUT /api/schedules/:id
```

**Access:** Admin only

---

#### ✅ Delete Schedule

```http
DELETE /api/schedules/:id
```

**Access:** Admin only

---

#### ⚠️ Toggle Schedule Availability

```http
PUT /api/schedules/:id/toggle
```

**Access:** Admin or assigned Doctor  
**Description:** Toggle slot between available/unavailable

---

#### 🔶 Get Available Slots

```http
GET /api/schedules/available
```

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| doctorId | string | Filter by doctor |
| dateFrom | string | Start date |
| dateTo | string | End date |

---

## 💬 Messaging

> **Critical:** Your frontend has a complete messaging system

#### ✅ List Messages

```http
GET /api/messages
```

**Headers:** `Authorization: Bearer <token>`  
**Access:** All authenticated users  
**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| type | string | `received`, `sent`, `all` |
| unreadOnly | boolean | Filter unread only |

**Response:**

```json
{
  "data": [
    {
      "id": "uuid",
      "fromId": "sender-uuid",
      "fromName": "Dr. Smith",
      "toId": "receiver-uuid",
      "toName": "John Doe",
      "subject": "Appointment Follow-up",
      "content": "Please remember to take your medication...",
      "date": "2026-01-09T10:00:00Z",
      "unread": true,
      "type": "received"
    }
  ]
}
```

---

#### ✅ Send Message

```http
POST /api/messages
```

**Headers:** `Authorization: Bearer <token>`  
**Request Body:**

```json
{
  "toId": "recipient-uuid",
  "subject": "Question about treatment",
  "content": "I have a question about my medication...",
  "type": "general"
}
```

---

#### ⚠️ Get Single Message

```http
GET /api/messages/:id
```

---

#### ✅ Mark Message as Read

```http
PUT /api/messages/:id/read
```

**Response:** `200 OK`

---

#### ⚠️ Delete Message

```http
DELETE /api/messages/:id
```

**Response:** `204 No Content`

---

#### ⚠️ Get Unread Message Count

```http
GET /api/messages/unread/count
```

**Response:**

```json
{
  "count": 5
}
```

---

## 📁 File Upload

#### 🔶 Upload File

```http
POST /api/upload
```

**Headers:**

- `Authorization: Bearer <token>`
- `Content-Type: multipart/form-data`

**Form Data:**
| Field | Type | Description |
|-------|------|-------------|
| file | file | The file to upload |
| type | string | `medical_record`, `profile_picture`, `attachment` |
| relatedId | string | Related entity ID |

**Response:**

```json
{
  "id": "file-uuid",
  "filename": "lab_results.pdf",
  "url": "https://storage.com/files/lab_results.pdf",
  "mimeType": "application/pdf",
  "size": 1024000
}
```

---

#### 🔶 Download/View File

```http
GET /api/files/:id
```

**Headers:** `Authorization: Bearer <token>`

---

## 📊 Analytics

> **Access:** Admin only

#### ✅ Get Dashboard Statistics

```http
GET /api/analytics/dashboard
```

**Response:**

```json
{
  "totalPatients": 150,
  "totalDoctors": 25,
  "pendingAppointments": 10,
  "completedToday": 5,
  "appointmentsThisWeek": 45,
  "appointmentsThisMonth": 180
}
```

---

#### 🔶 Appointment Analytics

```http
GET /api/analytics/appointments
```

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| dateFrom | string | Start date |
| dateTo | string | End date |
| groupBy | string | `day`, `week`, `month` |

---

#### 🔶 Doctor Performance Stats

```http
GET /api/analytics/doctors
```

**Response:**

```json
{
  "data": [
    {
      "doctorId": "uuid",
      "doctorName": "Dr. Smith",
      "totalAppointments": 50,
      "completedAppointments": 45,
      "averageRating": 4.8,
      "totalPatients": 35
    }
  ]
}
```

---

#### 🔶 Department Statistics

```http
GET /api/analytics/departments
```

**Response:**

```json
{
  "data": [
    {
      "department": "Cardiology",
      "doctorCount": 5,
      "patientCount": 150,
      "appointmentCount": 200
    }
  ]
}
```

---

#### 💡 Health Analytics

```http
GET /api/analytics/health
```

**Description:** Diagnosis patterns, common conditions, etc.

---

## 🚨 System Alerts

> **Access:** Admin only

#### 💡 Get System Alerts

```http
GET /api/system-alerts
```

**Response:**

```json
{
  "data": [
    {
      "id": "uuid",
      "type": "warning",
      "title": "Server Load High",
      "message": "CPU usage above 80%",
      "timestamp": "2026-01-09T10:00:00Z",
      "status": "active"
    }
  ]
}
```

---

#### 💡 Resolve Alert

```http
POST /api/system-alerts/:id/resolve
```

---

## 📦 Data Models

### User Roles

| Role      | Description            | Permissions                         |
| --------- | ---------------------- | ----------------------------------- |
| `admin`   | Hospital administrator | Full access to all endpoints        |
| `doctor`  | Medical practitioner   | Manage patients, records, schedules |
| `patient` | Hospital patient       | Book appointments, view own records |

### Appointment Status

| Status      | Description             | Transitions          |
| ----------- | ----------------------- | -------------------- |
| `pending`   | Awaiting admin approval | → approved, rejected |
| `approved`  | Confirmed by admin      | → completed          |
| `rejected`  | Declined by admin       | Terminal             |
| `completed` | Medical record created  | Terminal             |

### Message Types

| Type          | Description           |
| ------------- | --------------------- |
| `general`     | General communication |
| `appointment` | Appointment-related   |
| `medical`     | Medical information   |
| `system`      | System notifications  |

---

## 🚫 Error Handling

### HTTP Status Codes

| Code  | Description           |
| ----- | --------------------- |
| `200` | Success               |
| `201` | Created               |
| `204` | No Content            |
| `400` | Bad Request           |
| `401` | Unauthorized          |
| `403` | Forbidden             |
| `404` | Not Found             |
| `409` | Conflict              |
| `422` | Validation Error      |
| `500` | Internal Server Error |

### Error Codes

| Code                       | Description                 |
| -------------------------- | --------------------------- |
| `AUTH_INVALID_CREDENTIALS` | Wrong email/password        |
| `AUTH_TOKEN_EXPIRED`       | JWT token expired           |
| `AUTH_TOKEN_INVALID`       | Invalid JWT token           |
| `USER_NOT_FOUND`           | User does not exist         |
| `USER_ALREADY_EXISTS`      | Email already registered    |
| `APPOINTMENT_NOT_FOUND`    | Appointment does not exist  |
| `APPOINTMENT_CONFLICT`     | Time slot already booked    |
| `SCHEDULE_NOT_AVAILABLE`   | Schedule slot not available |
| `PERMISSION_DENIED`        | Insufficient permissions    |
| `VALIDATION_ERROR`         | Request validation failed   |

---

## ⚡ Rate Limiting

| Endpoint Type  | Limit                      |
| -------------- | -------------------------- |
| General        | 100 requests/minute/user   |
| Authentication | 5 login attempts/minute/IP |
| File Upload    | 10 uploads/minute/user     |

---

## 📋 Implementation Priority Checklist

### 🔴 Critical (Must Have)

- [x] `GET/PUT /api/users/me` - User profile management ✅
- [x] `GET/POST/DELETE /api/users` - User CRUD (admin) ✅
- [x] `GET /api/users/patients` - Patient listing for doctors ✅
- [ ] `DELETE /api/appointments/:id` - Cancel appointments
- [x] `GET/POST /api/messages` - Messaging system ✅
- [x] `PUT /api/messages/:id/read` - Mark message as read ✅
- [x] `POST /api/clinical-notes` - Create clinical notes ✅

### 🟠 High Priority

- [ ] `PUT /api/medical-records/:id` - Update records
- [ ] `DELETE /api/medical-records/:id` - Delete records
- [ ] `GET/PUT /api/doctors/me` - Doctor self-service
- [ ] `POST /api/auth/logout` - Logout
- [x] `POST /api/auth/change-password` - Password change ✅
- [ ] `PUT /api/appointments/:id/complete` - Complete appointment

### 🟡 Medium Priority

- [x] `GET/POST /api/health-updates` - Health tracking ✅
- [x] `POST/PUT/DELETE /api/schedules` - Schedule management (Doctor) ✅
- [ ] `POST /api/upload` - File uploads
- [x] `GET /api/analytics/dashboard` - Dashboard analytics ✅

### 🟢 Low Priority

- [ ] `POST /api/auth/forgot-password` - Password reset
- [ ] `GET /api/system-alerts` - System monitoring
- [ ] `GET /api/analytics/health` - Health analytics

---

> **Total APIs:** 65 endpoints  
> **Implemented:** 42 endpoints ✅  
> **Remaining:** 23 endpoints ⚠️🔶💡

---

## ✅ Implementation Progress (Updated Feb 8, 2026)

### Authentication

| Endpoint                         | Status     |
| -------------------------------- | ---------- |
| `POST /api/auth/register`        | ✅ Done    |
| `POST /api/auth/login`           | ✅ Done    |
| `POST /api/auth/change-password` | ✅ Done    |
| `POST /api/auth/logout`          | ⏳ Pending |
| `POST /api/auth/forgot-password` | ⏳ Pending |

### User Management

| Endpoint                      | Status          |
| ----------------------------- | --------------- |
| `GET /api/users/me`           | ✅ Done         |
| `PUT /api/users/me`           | ✅ Done         |
| `GET /api/users`              | ✅ Done (Admin) |
| `POST /api/users`             | ✅ Done (Admin) |
| `DELETE /api/users/:id`       | ✅ Done (Admin) |
| `GET /api/users/patients`     | ✅ Done         |
| `GET /api/users/patients/:id` | ✅ Done         |

### Appointments

| Endpoint                             | Status          |
| ------------------------------------ | --------------- |
| `GET /api/appointments`              | ✅ Done         |
| `POST /api/appointments`             | ✅ Done         |
| `GET /api/appointments/:id`          | ✅ Done         |
| `PUT /api/appointments/:id/approve`  | ✅ Done (Admin) |
| `PUT /api/appointments/:id/reject`   | ✅ Done (Admin) |
| `DELETE /api/appointments/:id`       | ⏳ Pending      |
| `PUT /api/appointments/:id/complete` | ⏳ Pending      |

### Doctors

| Endpoint                  | Status           |
| ------------------------- | ---------------- |
| `GET /api/doctors`        | ✅ Done (Public) |
| `POST /api/doctors`       | ✅ Done (Admin)  |
| `PUT /api/doctors/:id`    | ✅ Done (Admin)  |
| `DELETE /api/doctors/:id` | ✅ Done (Admin)  |
| `GET /api/doctors/me`     | ⏳ Pending       |
| `PUT /api/doctors/me`     | ⏳ Pending       |

### Schedules

| Endpoint                    | Status           |
| --------------------------- | ---------------- |
| `GET /api/schedules`        | ✅ Done          |
| `POST /api/schedules`       | ✅ Done (Doctor) |
| `PUT /api/schedules/:id`    | ✅ Done (Doctor) |
| `DELETE /api/schedules/:id` | ✅ Done (Doctor) |

### Medical Records

| Endpoint                          | Status     |
| --------------------------------- | ---------- |
| `GET /api/medical-records`        | ✅ Done    |
| `POST /api/medical-records`       | ✅ Done    |
| `GET /api/medical-records/:id`    | ✅ Done    |
| `PUT /api/medical-records/:id`    | ⏳ Pending |
| `DELETE /api/medical-records/:id` | ⏳ Pending |

### Clinical Notes

| Endpoint                         | Status     |
| -------------------------------- | ---------- |
| `POST /api/clinical-notes`       | ✅ Done    |
| `GET /api/clinical-notes`        | ✅ Done |
| `PUT /api/clinical-notes/:id`    | ✅ Done |
| `DELETE /api/clinical-notes/:id` | ✅ Done |

### Health Updates

| Endpoint                   | Status  |
| -------------------------- | ------- |
| `GET /api/health-updates`  | ✅ Done |
| `POST /api/health-updates` | ✅ Done |
| `DELETE /api/health-updates/:id` | ✅ Done |

### Messaging

| Endpoint                     | Status     |
| ---------------------------- | ---------- |
| `GET /api/messages`          | ✅ Done    |
| `POST /api/messages`         | ✅ Done    |
| `PUT /api/messages/:id/read` | ✅ Done    |
| `DELETE /api/messages/:id`   | ⏳ Pending |

### Analytics

| Endpoint                          | Status     |
| --------------------------------- | ---------- |
| `GET /api/analytics/dashboard`    | ✅ Done    |
| `GET /api/analytics/appointments` | ⏳ Pending |
| `GET /api/analytics/doctors`      | ⏳ Pending |
