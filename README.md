# BeRumahsakit

💧 RS Permata Sehat Hospital Management API - Built with Vapor web framework.

## Getting Started

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

---

## 📚 API Documentation

### Base URL
```
http://localhost:8080
```

### Interactive Documentation
- **Swagger UI**: `GET /api-docs`
- **OpenAPI JSON**: `GET /swagger.json`

---

## 🔓 Public Endpoints (No Authentication Required)

### Authentication

#### Register New User
```
POST /api/auth/register
```
**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "role": "patient"  // "admin", "doctor", or "patient"
}
```
**Response:** `User.Public` object

---

#### Login
```
POST /api/auth/login
```
**Request Body:**
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
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "patient"
  }
}
```

---

#### Change Password
```
POST /api/auth/change-password
```
**Access:** All authenticated users

**Request Body:**
```json
{
  "currentPassword": "oldPassword123",
  "newPassword": "newSecurePassword456"
}
```
**Response:**
```json
{
  "success": true,
  "message": "Password updated successfully"
}
```

---

### Doctors (Public)

#### List All Doctors
```
GET /api/doctors
```
**Response:** Array of `DoctorPublicResponse` objects
```json
[
  {
    "id": "uuid",
    "name": "Dr. Jane Smith",
    "specialty": "Cardiology",
    "status": "active",
    "experience": 10,
    "rating": 5.0,
    "bio": "Specialist in heart diseases",
    "education": "MD from University of Indonesia",
    "license": "STR-12345"
  }
]
```

---

#### Get Doctor Details
```
GET /api/doctors/:id
```
**Response:** `DoctorPublicResponse` object

---

## 🔒 Protected Endpoints (Authentication Required)

> **Note:** Include the JWT token in the Authorization header:
> ```
> Authorization: Bearer <your_token>
> ```

### Users

#### Get Current User
```
GET /api/users/me
```
**Access:** All authenticated users

**Response:** `UserResponse` object

---

#### Update Current User Profile
```
PUT /api/users/me
```
**Access:** All authenticated users

**Request Body:**
```json
{
  "name": "New Name",      // optional
  "email": "new@email.com" // optional
}
```
**Response:** Updated `UserResponse` object

---

#### List All Patients
```
GET /api/users/patients
```
**Access:** Doctors and Admins only

**Response:** Array of `UserResponse` objects (patients only)

---

#### Get Patient Details
```
GET /api/users/patients/:id
```
**Access:** Doctors and Admins only

**Response:** `UserResponse` object

---

#### List All Users
```
GET /api/users
```
**Access:** Admin only

**Response:** Array of `UserResponse` objects (all users)

---

#### Get User Details
```
GET /api/users/:id
```
**Access:** Admin only

**Response:** `UserResponse` object

---

#### Update User
```
PUT /api/users/:id
```
**Access:** Admin only

**Request Body:**
```json
{
  "name": "New Name",      // optional
  "email": "new@email.com" // optional
}
```
**Response:** Updated `UserResponse` object

---

#### Delete User
```
DELETE /api/users/:id
```
**Access:** Admin only

**Response:** `204 No Content`

---

### Appointments

#### List My Appointments
```
GET /api/appointments
```
**Access:** All authenticated users
- **Patients:** See only their own appointments
- **Admins:** See all appointments

**Response:** Array of `Appointment` objects

---

#### Book New Appointment
```
POST /api/appointments
```
**Access:** All authenticated users

**Request Body:**
```json
{
  "doctorId": "uuid-of-doctor",
  "date": "2024-06-01",
  "time": "09:00",
  "reason": "Regular checkup"
}
```
**Response:** Created `Appointment` object (status: "pending")

---

#### View Single Appointment
```
GET /api/appointments/:id
```
**Access:** Owner of appointment or Admin

**Response:** `Appointment` object with doctor and patient details

---

### Medical Records

#### List Medical Records
```
GET /api/medical-records
```
**Access:** All authenticated users
- **Patients:** See only their own records
- **Doctors/Admins:** See all records

**Response:** Array of `MedicalRecord` objects

---

#### Create Medical Record
```
POST /api/medical-records
```
**Access:** Doctors and Admins

**Request Body:**
```json
{
  "appointmentId": "uuid-of-appointment",
  "diagnosis": "Common cold",
  "symptoms": "Fever, cough, runny nose",
  "treatment": "Rest and hydration",
  "prescription": "Paracetamol 500mg",
  "notes": "Follow up in 1 week if symptoms persist"
}
```
**Response:** Created `MedicalRecord` object

> **Note:** Creating a medical record automatically marks the appointment as "completed"

---

#### View Medical Record Details
```
GET /api/medical-records/:id
```
**Access:** All authenticated users

**Response:** `MedicalRecord` object

---

### Health Updates

#### List Health Updates
```
GET /api/health-updates
```
**Access:** All authenticated users
- **Patients:** See only their own health updates
- **Doctors/Admins:** See all (or filter by `?patientId=uuid`)

**Query Parameters:**
- `patientId` (optional): Filter by patient UUID (Doctors/Admins only)

**Response:** Array of `HealthUpdate` objects

---

#### Log Health Update
```
POST /api/health-updates
```
**Access:** All authenticated users
- **Patients:** Create for themselves (no patientId needed)
- **Doctors/Admins:** Must specify `patientId`

**Request Body:**
```json
{
  "date": "2024-06-01",
  "weight": 70.5,
  "height": 175.0,
  "bloodPressure": "120/80",
  "bloodSugar": 95.0,
  "heartRate": 72,
  "sleepHours": 7.5,
  "mood": "good",
  "notes": "Feeling well today",
  "patientId": "uuid-of-patient"  // Required for Doctors/Admins
}
```
**Response:** Created `HealthUpdate` object

---

#### Delete Health Update
```
DELETE /api/health-updates/:id
```
**Access:** Owner of health update or Admin

**Response:** `204 No Content`

---

### Clinical Notes

#### List Clinical Notes
```
GET /api/clinical-notes
```
**Access:** Doctors and Admins only
- **Doctors:** See only notes they created
- **Admins:** See all notes

**Response:** Array of `ClinicalNote` objects

---

#### Create Clinical Note
```
POST /api/clinical-notes
```
**Access:** Doctors only

**Request Body:**
```json
{
  "patientId": "uuid-of-patient",
  "appointmentId": "uuid-of-appointment",
  "diagnosis": "Common cold",
  "treatment": "Rest and hydration",
  "notes": "Patient advised to rest for 3 days",
  "followUp": "2024-06-15",
  "status": "completed"  // "draft" or "completed"
}
```
**Response:** Created `ClinicalNote` object

---

#### Get Clinical Note Details
```
GET /api/clinical-notes/:id
```
**Access:** Doctors and Admins

**Response:** `ClinicalNote` object

---

#### Update Clinical Note
```
PUT /api/clinical-notes/:id
```
**Access:** Creator (Doctor) or Admin

**Request Body:**
```json
{
  "diagnosis": "Updated diagnosis",
  "treatment": "Updated treatment",
  "notes": "Updated notes",
  "followUp": "2024-06-20",
  "status": "completed"
}
```
**Response:** Updated `ClinicalNote` object

---

#### Delete Clinical Note
```
DELETE /api/clinical-notes/:id
```
**Access:** Admin only

**Response:** `204 No Content`

---

## 👮 Admin Only Endpoints

> **Note:** These endpoints require Admin role. Non-admin users will receive `403 Forbidden`.

### Doctors Management

#### Create Doctor
```
POST /api/doctors
```
**Request Body:**
```json
{
  "name": "Dr. Jane Smith",
  "email": "jane.smith@hospital.com",
  "password": "optionalPassword123",
  "phone": "+62812345678",
  "specialty": "Cardiology",
  "status": "active",
  "license": "STR-12345",
  "experience": 10,
  "education": "MD from University of Indonesia",
  "bio": "Specialist in heart diseases",
  "joinDate": "2020-01-15",
  "totalPatients": 0,
  "rating": 5.0
}
```
**Response:** Created `Doctor` object

> **Note:** If password is not provided, defaults to "password123". A User account with role "doctor" is automatically created.

---

#### Update Doctor
```
PUT /api/doctors/:id
```
**Request Body:** Same as Create Doctor (excluding password)

**Response:** Updated `Doctor` object

---

#### Delete Doctor
```
DELETE /api/doctors/:id
```
**Response:** `204 No Content`

---

### Schedules Management

#### List Schedules
```
GET /api/schedules
```
**Query Parameters:**
- `doctorId` (optional): Filter by doctor UUID

**Response:** Array of `Schedule` objects

---

#### Generate Schedule Slots
```
POST /api/schedules/generate
```
**Request Body:**
```json
{
  "doctorId": "uuid-of-doctor",
  "date": "2024-01-30"
}
```
**Response:** `201 Created`

> **Note:** Automatically creates time slots: 09:00, 10:00, 11:00, 13:00, 14:00, 15:00

---

### Appointment Management (Admin Actions)

#### Approve Appointment
```
PUT /api/appointments/:id/approve
```
**Response:** Updated `Appointment` object (status: "approved")

---

#### Reject Appointment
```
PUT /api/appointments/:id/reject
```
**Response:** Updated `Appointment` object (status: "rejected")

---

### Analytics Dashboard

#### Get Dashboard Statistics
```
GET /api/analytics/dashboard
```
**Response:**
```json
{
  "totalPatients": 150,
  "totalDoctors": 25,
  "pendingAppointments": 10,
  "completedToday": 5
}
```

---

## 📋 Data Models

### User Roles
| Role | Description |
|------|-------------|
| `admin` | Full access to all endpoints |
| `doctor` | Can create medical records and clinical notes |
| `patient` | Can book appointments, view own records, log health updates |

### Appointment Status
| Status | Description |
|--------|-------------|
| `pending` | Awaiting admin approval |
| `approved` | Confirmed by admin |
| `rejected` | Declined by admin |
| `completed` | Medical record created |

### Clinical Note Status
| Status | Description |
|--------|-------------|
| `draft` | Note is still being edited |
| `completed` | Note is finalized |

---

## 🔗 See More

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)
