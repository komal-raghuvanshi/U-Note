USE u_note;

ALTER TABLE requests
    ADD COLUMN fulfilled_by INT NULL,
    ADD COLUMN fulfilled_resource_id INT NULL,
    ADD CONSTRAINT fk_requests_fulfilled_by
        FOREIGN KEY (fulfilled_by) REFERENCES users(user_id),
    ADD CONSTRAINT fk_requests_fulfilled_resource
        FOREIGN KEY (fulfilled_resource_id)
        REFERENCES resources(resource_id) ON DELETE RESTRICT;
