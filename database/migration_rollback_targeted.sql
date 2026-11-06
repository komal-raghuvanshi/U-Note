-- ====================================================================
-- U-NOTE: Production Database Migration - TARGETED ROLLBACK SCRIPT
-- Target: Aiven MySQL (defaultdb)
-- Safe, surgical rollback driven entirely by `migration_ledger`.
-- NEVER deletes pre-existing Cloud data or records created by users after migration.
-- ====================================================================

START TRANSACTION;

-- 1. Remove migrated saved_resources recorded in ledger
DELETE sr FROM saved_resources sr
JOIN users u ON sr.user_id = u.user_id
JOIN resources r ON sr.resource_id = r.resource_id
WHERE CONCAT(u.email, ':', r.resource_url) IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'saved_resources'
);

-- 2. Remove migrated requests recorded in ledger
DELETE req FROM requests req
JOIN users u ON req.user_id = u.user_id
WHERE CONCAT(u.email, ':', req.request_description) IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'requests'
);

-- 3. Remove migrated resources recorded in ledger
-- Safety check: Only deletes if not referenced by subsequent requests, ratings, or saved_resources
DELETE r FROM resources r
WHERE r.resource_url IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'resources'
)
AND NOT EXISTS (SELECT 1 FROM requests req WHERE req.fulfilled_resource_id = r.resource_id)
AND NOT EXISTS (SELECT 1 FROM ratings rat WHERE rat.resource_id = r.resource_id)
AND NOT EXISTS (SELECT 1 FROM saved_resources sr WHERE sr.resource_id = r.resource_id);

-- 4. Remove migrated user (only if user has no subsequent activity)
DELETE u FROM users u
WHERE u.email IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'users'
)
AND NOT EXISTS (SELECT 1 FROM resources r WHERE r.uploaded_by = u.user_id)
AND NOT EXISTS (SELECT 1 FROM requests req WHERE req.user_id = u.user_id)
AND NOT EXISTS (SELECT 1 FROM ratings rat WHERE rat.user_id = u.user_id);

-- 5. Remove units seeded for curriculum subjects recorded in ledger
DELETE u FROM units u
JOIN subjects s ON u.subject_id = s.subject_id
WHERE CONCAT(s.subject_code, ':Unit ', u.unit_number) IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'units'
)
AND NOT EXISTS (SELECT 1 FROM resources r WHERE r.unit_id = u.unit_id)
AND NOT EXISTS (SELECT 1 FROM requests req WHERE req.unit_id = u.unit_id);

-- 6. Remove catalogue metadata rows recorded in ledger
DELETE m FROM subject_catalogue_metadata m
WHERE m.catalogue_code IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'subject_catalogue_metadata'
);

-- 7. Remove curriculum subjects recorded in ledger
DELETE s FROM subjects s
JOIN semesters sem ON s.semester_id = sem.semester_id
JOIN branches b ON sem.branch_id = b.branch_id
WHERE CONCAT(b.branch_name, ':', sem.semester_name, ':', s.subject_code) IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'subjects'
)
AND NOT EXISTS (SELECT 1 FROM resources r WHERE r.subject_id = s.subject_id)
AND NOT EXISTS (SELECT 1 FROM requests req WHERE req.subject_id = s.subject_id);

-- 8. Remove DS semesters recorded in ledger
DELETE sem FROM semesters sem
JOIN branches b ON sem.branch_id = b.branch_id
WHERE CONCAT(b.branch_name, ':', sem.semester_name) IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'semesters'
)
AND NOT EXISTS (SELECT 1 FROM subjects s WHERE s.semester_id = sem.semester_id);

-- 9. Remove DS branch recorded in ledger
DELETE b FROM branches b
WHERE b.branch_name IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'branches'
)
AND NOT EXISTS (SELECT 1 FROM semesters sem WHERE sem.branch_id = b.branch_id);

-- 10. Remove BLOB files recorded in ledger
DELETE rf FROM resource_files rf
WHERE rf.filename IN (
    SELECT entity_natural_key FROM migration_ledger
    WHERE migration_name = 'sync_local_to_cloud' AND table_name = 'resource_files'
);

-- 11. Clear ledger entries for this migration
DELETE FROM migration_ledger WHERE migration_name = 'sync_local_to_cloud';

COMMIT;
