# U-NOTE

U-NOTE is a React + Vite frontend and Flask + MySQL platform for sharing and finding RGPV study resources.

## Features

- Browse resources from MySQL and filter by branch, semester, subject, unit, search term, and resource type.
- Upload PDFs and images, or submit YouTube resource links, with branch → semester → subject → unit metadata.
- View and download uploaded files, rate resources, save resources, and delete a resource only as its authenticated uploader.
- Browse community study requests publicly, with requester identities hidden from anonymous viewers. Authenticated users can submit and manage their own requests; identical pending requests are rejected and fulfillment occurs by linking a shared resource.
- Create accounts, log in, and update profile name and academic information.

## Local setup

### Database

Create a MySQL database and tables by running `database/scheme.sql` on a fresh database. To update an existing database, inspect the applicable migration and current table contents first, then make a backup before applying it. `database/migration_add_branches_and_units.sql` seeds the original branch/unit setup and uses subject IDs that must match the target database. `database/migration_add_aiml_catalogue_and_ds.sql` additively seeds the AIML subject catalogue, elective metadata, and the DS branch with semesters only. No migration is run automatically by the application.

Set the backend environment variables before starting Flask. The connector uses
the configured values directly; only the port has a default:

| Variable | Required/default | Description |
|---|---|---|
| `UNOTE_DB_HOST` | Required | MySQL host |
| `UNOTE_DB_PORT` | `3306` | MySQL port |
| `UNOTE_DB_USER` | Required | MySQL user |
| `UNOTE_DB_PASSWORD` | Required | MySQL password |
| `UNOTE_DB_NAME` | Required | Database name (`u_note` locally; Aiven production uses `defaultdb`) |
| `UNOTE_SECRET_KEY` | Required for authentication | Set a long, random value |
| `UNOTE_CORS_ORIGINS` | `http://localhost:5173,http://127.0.0.1:5173` | Comma-separated allowed frontend origins |
| `UNOTE_EMAIL` | Optional | Sender email account for OTP verification & contact form (Gmail) |
| `UNOTE_EMAIL_APP_PASSWORD` | Optional | App password for the sender email account |
| `RESEND_API_KEY` | Optional | Resend API key for OTP delivery (Priority 1) |
| `BREVO_API_KEY` | Optional | Brevo API key for OTP delivery (Priority 2) |
| `EMAIL_SENDER_NAME` | `U-NOTE` | Sender display name for emails |
| `SMTP_HOST` | `smtp.gmail.com` | Custom SMTP host if not using default Gmail |
| `SMTP_PORT` | `587` | Custom SMTP port |

Keep credentials in environment variables; do not commit them. Existing sessions are signed, expire after seven days, and are stored by the frontend in browser local storage.

### Aiven and Vercel

- Place Aiven's public CA certificate at `backend/ca.pem`. Connections to Aiven hosts use that certificate with certificate and hostname verification enabled. Local non-Aiven MySQL connections do not use the Aiven CA.
- Configure `UNOTE_DB_HOST`, `UNOTE_DB_PORT`, `UNOTE_DB_USER`, `UNOTE_DB_PASSWORD`, `UNOTE_DB_NAME`, and `UNOTE_SECRET_KEY` in each Vercel environment that needs the backend. Use a separate database/user and secret for Preview rather than production data. Set `UNOTE_CORS_ORIGINS` if the frontend is served from a different origin.
- Local development can use the same Aiven database by setting the same connection variables in `backend/.env`; Aiven connections must use `UNOTE_DB_NAME=defaultdb`. The backend requires an explicit database host and has no implicit localhost database fallback.
- To enable the contact form, configure `UNOTE_EMAIL` and `UNOTE_EMAIL_APP_PASSWORD` for the backend's SMTP sender in the Vercel environments where contact messages should be delivered. The form submits to Flask; these values are never sent to the browser.
- The production frontend uses the same-origin `/api` path by default, so `VITE_API_BASE_URL` is only needed when the API is hosted elsewhere. It is a build-time Vite variable.
- Do not run `database/scheme.sql` or a migration against Aiven without reviewing its target: the schema bootstrap and several existing SQL files explicitly select `u_note`, while the production database is `defaultdb`. Migrations are not run automatically.
- Resource uploads and profile photos are persisted in the MySQL `resource_files` table and served from there in production; Vercel's temporary directory is only a local fallback. New file writes fail rather than report success if persistent storage is unavailable.
- `database/migration_phase_c_blob_files.py` copies only files referenced by active resource URLs or profile-photo records. It verifies existing Cloud content and never overwrites a conflicting file. Unreferenced local uploads are deliberately skipped.
- Apply `database/migration_phase_d_exact_ledger.sql` as an additive migration before using the guarded Phase B runner. It creates an exact-primary-key ledger for newly inserted rows and does not backfill legacy natural-key entries.
- Inspect Phase B with `python _run_phase_b.py`; the runner is read-only unless `--execute` is passed. It refuses to run when legacy or exact entries already exist, and it requires the associated account to have been provisioned separately. Never execute `migration_phase_b_dml.sql` directly.

#### Current Aiven recovery status

The Aiven `defaultdb` was verified read-only on 2026-11-06. Phase A's expected columns, tables, foreign keys, and nullable unit name are present. All 327 expected Phase B target rows were found, but the legacy ledger has only 326 natural-key entries: the user row is untracked, and a request ledger key is ambiguous across multiple request rows. Those historical entries have not been backfilled into the exact-primary-key ledger because their provenance cannot be proved from current records. Do not rerun Phase B or the targeted rollback until that provenance is established from an authoritative historical backup.

Phase C migrated five active mapped files (6,790,036 bytes). Their Cloud sizes, MIME types, SHA-256 digests, and exact file primary-key ledger entries were verified. Six local files were not mapped to active resources or profile-photo records and were intentionally not migrated.

### Backend

From the repository root, install `backend/requirements.txt` in a Python environment, set the variables above, and run:

```powershell
python backend\app.py
```

Local resource uploads are stored in `backend/uploads` and are limited to 25 MB; local profile photos are limited to 5 MB. On Vercel, both upload types are limited to 4 MB to stay within the function request-body cap, then persisted in the Aiven `resource_files` table. Keep each upload below the configured limit.

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
