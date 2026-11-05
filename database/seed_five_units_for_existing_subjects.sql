-- Repeatable seed for existing subjects only.
-- Adds Unit 1 through Unit 5 where missing; preserves all existing rows.
-- All unit names are NULL because no unit-topic content is being added.

USE u_note;

INSERT INTO units (subject_id, unit_number, unit_name)
SELECT subjects.subject_id, unit_numbers.unit_number, NULL
FROM subjects
CROSS JOIN (
    SELECT 1 AS unit_number
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) AS unit_numbers
LEFT JOIN units existing
    ON existing.subject_id = subjects.subject_id
   AND existing.unit_number = unit_numbers.unit_number
WHERE existing.unit_id IS NULL;
