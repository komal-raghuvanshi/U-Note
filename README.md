# U-NOTE

U-NOTE is a React + Vite frontend and Flask + MySQL platform for sharing and finding RGPV study resources.

## Features

- Browse resources from MySQL and filter by branch, semester, subject, unit, search term, and resource type.
- Upload PDFs and images, or submit YouTube resource links, with branch → semester → subject → unit metadata.
- View and download uploaded files, rate resources, save resources, and delete a resource only as its authenticated uploader.
- Create and track study-resource requests. Request owners and authenticated teachers can update request status.
- Create accounts, log in, and update profile name and academic information.

## Local setup

### Database

Create a MySQL database and tables by running `database/scheme.sql` on a fresh database. To update an existing database, inspect the applicable migration and current table contents first, then make a backup before applying it. `database/migration_add_branches_and_units.sql` seeds the original branch/unit setup and uses subject IDs that must match the target database. `database/migration_add_aiml_catalogue_and_ds.sql` additively seeds the AIML subject catalogue, elective metadata, and the DS branch with semesters only. No migration is run automatically by the application.

Set the backend environment variables before starting Flask:

| Variable | Default | Description |
|---|---|---|
| `UNOTE_DB_HOST` | `localhost` | MySQL host |
| `UNOTE_DB_PORT` | `3306` | MySQL port |
| `UNOTE_DB_USER` | `root` | MySQL user |
| `UNOTE_DB_PASSWORD` | empty | MySQL password |
| `UNOTE_DB_NAME` | `u_note` | Database name |
| `UNOTE_SECRET_KEY` | none | Required to create or validate login sessions; set a long random value |
| `UNOTE_CORS_ORIGINS` | `http://localhost:5173,http://127.0.0.1:5173` | Comma-separated allowed frontend origins |

Keep credentials in environment variables; do not commit them. Existing sessions are signed, expire after seven days, and are stored by the frontend in browser local storage.

### Backend

From the repository root, install `backend/requirements.txt` in a Python environment, set the variables above, and run:

```powershell
python backend\app.py
```

Uploaded files are stored in `backend/uploads` and are limited to 25 MB. Back up this folder along with the MySQL database.

### Frontend

```powershell
cd frontend
npm install
npm run dev
```

The frontend defaults to `http://127.0.0.1:5000` for Flask. Set `VITE_API_BASE_URL` before building if the backend runs at a different address.

## Validation

```powershell
cd frontend
npm run lint
npm run build
cd ..
python -m unittest discover -s backend\tests -p "test_*.py" -v
```

The live integration tests are skipped unless `UNOTE_RUN_LIVE_TESTS=1` is set. They create and remove a test resource, so run them only against a disposable database after confirming the configured user and schema.

## Existing project documentation

Database diagrams are under `Documentation/Diagram`. AIML semester-four resource availability notes are in `resources/aiml_sem4`.
