CREATE OR REPLACE FUNCTION wipe_reconstruction(
       source_param varchar(6)
) RETURNS void AS $$
BEGIN
    DELETE FROM task_history
     WHERE source = source_param;

    DELETE FROM task_milestone
     WHERE source = source_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION build_edges(
       run_date date,
       project_id_list int array) RETURNS void AS $$
DECLARE
  dayrow record;
  taskrow record;
  projrow record;
  project_id int;
BEGIN

    FOR taskrow IN SELECT id
                     FROM maniphest_task
                    ORDER BY id
    LOOP
        FOR projrow IN SELECT active_projects
                         FROM maniphest_transaction
                        WHERE date_modified <= run_date
                          AND task_id = taskrow.id
                          AND has_edge_data IS TRUE
                     ORDER BY date_modified DESC
                        LIMIT 1
        LOOP
            FOREACH project_id IN ARRAY projrow.active_projects & project_id_list
            LOOP
                INSERT INTO maniphest_edge
                     VALUES (taskrow.id, project_id, run_date);
            END LOOP;
        END LOOP;
    END LOOP;     

    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION find_descendents(
       root_id int,
       run_date date
) RETURNS TABLE(id int) AS $$
BEGIN
  RETURN query
  WITH RECURSIVE search_mb(parent_id, child_id, depth, path, cycle) AS (
        SELECT parent_id,
	       child_id,
	       1,
	       ARRAY[parent_id],
               false
        FROM maniphest_blocked mb
       WHERE parent_id = root_id
      UNION ALL
        SELECT mb.parent_id,
	       mb.child_id,
	       smb.depth + 1,
               path || mb.parent_id,
               mb.parent_id = ANY(path)
        FROM maniphest_blocked mb, search_mb smb
        WHERE mb.parent_id = smb.child_id AND NOT cycle
  )
  SELECT child_id FROM search_mb;

END;
$$ LANGUAGE plpgsql;
