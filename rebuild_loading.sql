-- Tables for loading

CREATE EXTENSION IF NOT EXISTS intarray;

DROP TABLE IF EXISTS maniphest_edge;
DROP TABLE IF EXISTS maniphest_blocked;
DROP TABLE IF EXISTS maniphest_transaction;
DROP TABLE IF EXISTS maniphest_task;
DROP TABLE IF EXISTS phabricator_column;
DROP TABLE IF EXISTS phabricator_project;

CREATE TABLE phabricator_project (
       id int primary key,
       name text,
       phid text unique
);

CREATE TABLE maniphest_task (
       id int primary key,
       phid text unique,
       title text,
       story_points text
);

CREATE TABLE phabricator_column (
       id int primary key,
       phid text unique,
       name text,
       project_phid text references phabricator_project (phid)
);

CREATE TABLE maniphest_transaction (
       id int primary key,
       phid text unique,
       task_id int,
       object_phid text,
       transaction_type text,
       new_value text,
       date_modified timestamp,
       has_edge_data boolean,
       active_projects int array
);

CREATE INDEX ON maniphest_transaction (task_id, date_modified, has_edge_data);

CREATE TABLE maniphest_edge (
       task int references maniphest_task,
       project int references phabricator_project,
       edge_date date
);

-- TODO: maybe add the indexes after all rows are added?
CREATE INDEX ON maniphest_edge (task, project, edge_date);
CREATE INDEX ON maniphest_edge (task);
CREATE INDEX ON maniphest_edge (project);



DROP TABLE IF EXISTS maniphest_blocked_phid;

-- No RI for this table because otherwise we would have to load all
-- tasks before any blocks
CREATE TABLE maniphest_blocked_phid (
       blocked_date date,
       phid text,
       blocked_phid text
);

CREATE TABLE maniphest_blocked (
       blocked_date date,
       id int references maniphest_task (id),
       blocked_id int references maniphest_task (id)
);

CREATE INDEX ON maniphest_blocked (id);
CREATE INDEX ON maniphest_blocked (blocked_id);