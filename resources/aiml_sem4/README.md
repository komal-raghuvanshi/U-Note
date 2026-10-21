# U-NOTE AIML Semester 4 Resources

## What is included
- `resource_availability.csv`: verified entry points for the official RGPV IV-semester syllabus and subject-specific PYQ/resource pages.
- SQL seed file: `database/aiml_sem4_resources.sql`.

## Important availability note
This folder does **not** contain copied PDF files for class notes, handwritten notes, or important-question sets. Those files were not downloaded and checked locally, so they are intentionally marked as not bundled rather than being presented as available PDFs. The linked provider pages may list online notes, important questions, and papers; open each item and confirm access before demoing it.

## Official syllabus
The RGPV syllabus PDF is linked from the official RGPV domain:
https://www.rgpv.ac.in/CDN/PubContent/Scheme/IV_sem_BTech_AIML230222083345.pdf

## Database safety
The SQL script:
- targets AL401–AL405 under `Semester 4`;
- uses uploader `user_id = 1` based on the current database check;
- inserts only when the same subject + URL + resource type does not already exist;
- does not delete or update existing resources;
- leaves `unit_id` NULL for semester-wide syllabus and PYQ index pages because those links cover more than one unit.

Before running the SQL file, confirm the table schema matches the existing U-NOTE database. Then run it once in MySQL Workbench and inspect the final verification query.
