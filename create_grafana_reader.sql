-- Create the Grafana read-only login before restoring wh3_analysis.sql.
-- Set its password separately; do not store credentials in this file.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_roles
        WHERE rolname = 'grafana_reader'
    ) THEN
        CREATE ROLE grafana_reader LOGIN;
    END IF;
END
$$;