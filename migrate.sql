-- =============================================================================
-- BookDB v1 -> v2 (Hierarchical) Migration Script
-- =============================================================================
--
-- This script migrates a v1 BookDB database to the v2 schema, which introduces
-- a true hierarchy: project -> docspace -> varstore -> var.
--
-- !!! IMPORTANT !!!
-- 1. BACK UP YOUR DATABASE BEFORE RUNNING THIS SCRIPT.
-- 2. This script is intended to be run on a NEW, EMPTY database file while
--    reading from the OLD database.
--
-- USAGE:
--   1. Make a backup:
--      cp my_app.sqlite my_app.sqlite.bak
--
--   2. Run from the command line:
--      sqlite3 new_database.sqlite ".read migrate.sql"
--
--      (The script will prompt you for the path to the old database.)
--
-- =============================================================================

-- --- PREPARATION ---

-- Turn off foreign key constraints during the migration for performance
-- and to avoid dependency errors. We will re-enable them at the end.
PRAGMA foreign_keys = OFF;

-- Wrap the entire migration in a single transaction. If any part fails,
-- the entire operation will be rolled back, leaving the new database clean.
BEGIN TRANSACTION;

-- --- ATTACH OLD DATABASE ---

-- Prompt the user for the old database file and attach it.
-- This allows us to query tables from both the new and old databases.
.print 'Please enter the path to the OLD database file to migrate:'
.prompt '> ' old_db_path
ATTACH DATABASE :old_db_path AS old_db;
.print 'Attaching ' || :old_db_path || ' as old_db... done.'


-- --- STEP 1: CREATE THE NEW HIERARCHICAL SCHEMA ---

.print 'Creating new v2 schema (projects, docspaces, varstores, vars)...'

-- The new top-level entity
CREATE TABLE IF NOT EXISTS projects (
    p_id    INTEGER PRIMARY KEY,
    p_name  TEXT UNIQUE NOT NULL
);

-- The new documentation namespace layer, children of projects
CREATE TABLE IF NOT EXISTS docspaces (
    d_id      INTEGER PRIMARY KEY,
    d_name    TEXT NOT NULL,
    p_id_fk   INTEGER NOT NULL,
    FOREIGN KEY (p_id_fk) REFERENCES projects(p_id) ON DELETE CASCADE,
    UNIQUE (d_name, p_id_fk)
);

-- The new "varstore" table (formerly keyval_ns), children of docspaces
CREATE TABLE IF NOT EXISTS varstores (
    vs_id     INTEGER PRIMARY KEY,
    vs_name   TEXT NOT NULL,
    d_id_fk   INTEGER NOT NULL,
    FOREIGN KEY (d_id_fk) REFERENCES docspaces(d_id) ON DELETE CASCADE,
    UNIQUE (vs_name, d_id_fk)
);

-- The new variables table, children of varstores
CREATE TABLE IF NOT EXISTS vars (
    v_id        INTEGER PRIMARY KEY,
    v_key       TEXT NOT NULL,
    v_value     TEXT,
    v_updated   INTEGER,
    vs_id_fk    INTEGER NOT NULL,
    FOREIGN KEY (vs_id_fk) REFERENCES varstores(vs_id) ON DELETE CASCADE,
    UNIQUE (v_key, vs_id_fk)
);

.print 'Schema creation complete.'


-- --- STEP 2: MIGRATE THE DATA ---

.print 'Migrating data from old_db to new schema...'

-- 2a. Migrate projects (1-to-1 mapping)
INSERT INTO main.projects (p_id, p_name)
SELECT pns_id, pns_name
FROM old_db.project_ns;

.print '  -> Migrated projects.'

-- 2b. Create a default "docspace" for each migrated project.
-- All old varstores will be placed inside this default docspace.
-- We'll name it '_main' to signify its special, auto-generated status.
INSERT INTO main.docspaces (d_name, p_id_fk)
SELECT '_main', p_id
FROM main.projects;

.print '  -> Created default ''_main'' docspaces.'

-- 2c. Migrate old keyval_ns entries to the new varstores table.
-- This requires joining across both databases to link the old keyval_ns
-- to its new parent: the default '_main' docspace we just created.
INSERT INTO main.varstores (vs_id, vs_name, d_id_fk)
SELECT
    old_k.kvns_id,        -- Keep the original ID for consistency
    old_k.kvns_name,      -- The name is the same
    new_d.d_id            -- The foreign key to the new parent docspace
FROM
    old_db.keyval_ns AS old_k
JOIN
    old_db.project_ns AS old_p ON old_k.pns_id_fk = old_p.pns_id
JOIN
    main.projects AS new_p ON old_p.pns_name = new_p.p_name
JOIN
    main.docspaces AS new_d ON new_p.p_id = new_d.p_id AND new_d.d_name = '_main';

.print '  -> Migrated keyval_ns to varstores.'

-- 2d. Migrate the variables themselves.
-- This is the final step, re-parenting each variable to its new varstore.
INSERT INTO main.vars (v_id, v_key, v_value, v_updated, vs_id_fk)
SELECT
    old_v.var_id,
    old_v.var_key,
    old_v.var_value,
    old_v.var_updated,
    old_v.kvns_id_fk      -- The foreign key is the same ID as the varstore ID
FROM
    old_db.vars AS old_v;

.print '  -> Migrated variables.'
.print 'Data migration complete.'


-- --- FINALIZATION ---

-- Detach the old database, we are done with it.
DETACH DATABASE old_db;

-- Re-enable foreign key constraints.
PRAGMA foreign_keys = ON;

-- Commit the transaction, making all changes permanent.
COMMIT;

.print ' '
.print '============================================================================='
.print ' MIGRATION SUCCEEDED!'
.print ' The new database file is now populated with the v2 hierarchical schema.'
.print '============================================================================='
.print ' '
