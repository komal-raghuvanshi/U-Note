-- U-NOTE: AIML Semester 4 resource seed (safe, repeatable)
-- Scope: AL-401-AL-405 only. Does not delete or modify existing rows.
-- Requires the existing schema columns:
-- subjects(subject_id, subject_code, subject_name, semester_id)
-- semesters(semester_id, semester_name)
-- resources(title, resource_url, resource_type, subject_id, uploaded_by,
--           unit_id, description)
-- Existing DSLA video is preserved. Re-running this script should not duplicate
-- rows with the same subject + URL + resource type.

USE u_note;

START TRANSACTION;

-- Add links to the official RGPV IV-semester syllabus and subject-specific PYQ/resource pages.
-- These are web resources, not locally bundled PDF files.
INSERT INTO resources
    (title, resource_url, resource_type, subject_id, uploaded_by, unit_id, description)
SELECT
    seed.title,
    seed.resource_url,
    seed.resource_type,
    s.subject_id,
    1,
    NULL,
    seed.description
FROM (
    SELECT 'AL-401' AS subject_code,
           'RGPV AIML IV Semester Official Syllabus (includes AL-401)' AS title,
           'https://www.rgpv.ac.in/CDN/PubContent/Scheme/IV_sem_BTech_AIML230222083345.pdf' AS resource_url,
           'Official Syllabus' AS resource_type,
           'Official RGPV syllabus PDF; covers the AIML IV-semester syllabus.' AS description
    UNION ALL
    SELECT 'AL-401', 'AL-401 Previous Year Papers and Study Resources',
           'https://campusprep.in/rgpv/aiml/sem-4/al-401/',
           'PYQ / Study Resources',
           'Subject resource page listing syllabus, notes, important questions and previous-year papers; verify each item on the provider page.'
    UNION ALL
    SELECT 'AL-402', 'RGPV AIML IV Semester Official Syllabus (includes AL-402)',
           'https://www.rgpv.ac.in/CDN/PubContent/Scheme/IV_sem_BTech_AIML230222083345.pdf',
           'Official Syllabus',
           'Official RGPV syllabus PDF; covers the AIML IV-semester syllabus.'
    UNION ALL
    SELECT 'AL-402', 'AL-402 Previous Year Papers and Study Resources',
           'https://campusprep.in/rgpv/aiml/sem-4/al-402/',
           'PYQ / Study Resources',
           'Subject resource page listing syllabus, notes, important questions and previous-year papers; verify each item on the provider page.'
    UNION ALL
    SELECT 'AL-403', 'RGPV AIML IV Semester Official Syllabus (includes AL-403)',
           'https://www.rgpv.ac.in/CDN/PubContent/Scheme/IV_sem_BTech_AIML230222083345.pdf',
           'Official Syllabus',
           'Official RGPV syllabus PDF; covers the AIML IV-semester syllabus.'
    UNION ALL
    SELECT 'AL-403', 'AL-403 Previous Year Papers and Study Resources',
           'https://campusprep.in/rgpv/aiml/sem-4/al-403/previous-year-papers/',
           'PYQ / Study Resources',
           'Subject page lists previous-year papers and links to notes/important questions; verify individual items on the provider page.'
    UNION ALL
    SELECT 'AL-404', 'RGPV AIML IV Semester Official Syllabus (includes AL-404)',
           'https://www.rgpv.ac.in/CDN/PubContent/Scheme/IV_sem_BTech_AIML230222083345.pdf',
           'Official Syllabus',
           'Official RGPV syllabus PDF; covers the AIML IV-semester syllabus.'
    UNION ALL
    SELECT 'AL-404', 'AL-404 Computer Organization and Architecture Previous Year Papers',
           'https://campusprep.in/rgpv/aiml/sem-4/al-404/previous-year-papers/',
           'PYQ / Study Resources',
           'Subject-specific previous-year-paper index; individual papers are linked from the provider page.'
    UNION ALL
    SELECT 'AL-405', 'RGPV AIML IV Semester Official Syllabus (includes AL-405)',
           'https://www.rgpv.ac.in/CDN/PubContent/Scheme/IV_sem_BTech_AIML230222083345.pdf',
           'Official Syllabus',
           'Official RGPV syllabus PDF; covers the AIML IV-semester syllabus.'
    UNION ALL
    SELECT 'AL-405', 'AL-405 Machine Learning Previous Year Papers',
           'https://campusprep.in/rgpv/aiml/sem-4/al-405/previous-year-papers/',
           'PYQ / Study Resources',
           'Subject-specific previous-year-paper index; individual papers are linked from the provider page.'
) AS seed
JOIN subjects s
  ON s.subject_code = seed.subject_code
JOIN semesters sem
  ON sem.semester_id = s.semester_id
 AND sem.semester_name = 'Semester 4'
WHERE NOT EXISTS (
    SELECT 1
    FROM resources existing
    WHERE existing.subject_id = s.subject_id
      AND existing.resource_url = seed.resource_url
      AND existing.resource_type = seed.resource_type
);

COMMIT;

-- Verification after running:
SELECT s.subject_code, s.subject_name, r.title, r.resource_type, r.resource_url
FROM subjects s
LEFT JOIN resources r ON r.subject_id = s.subject_id
WHERE s.subject_code IN ('AL-401','AL-402','AL-403','AL-404','AL-405')
  AND s.semester_id = (
      SELECT semester_id FROM semesters WHERE semester_name = 'Semester 4'
  )
ORDER BY s.subject_code, r.resource_type, r.title;
