-- Function as next operation
-- authed by Yutaka Konishi
-- 2006/8/9
CREATE FUNCTION next(integer,integer,integer) RETURNS void AS $$
  $query_before_shell = "INSERT INTO rule_search_time_logs (user_id, time_name, time_value) VALUES('".$_[0]."','before_shell','now')";
  spi_exec_query($query_before_shell);

  $action = `sh /home/learn/rails_app/adel_v2/teaching_materials/eca_rules/run.sh next dummy,dummy $_[0] $_[1]`;
  $query = "INSERT INTO action_logs (user_id,action_code,created_on,dis_code) VALUES('".$_[0]."','".$action."','now','".$_[2]."')";
  spi_exec_query($query);

  $query_after_shell = "INSERT INTO rule_search_time_logs (user_id, time_name, time_value) VALUES('".$_[0]."','after_shell','now')";
 spi_exec_query($query_after_shell);
$$LANGUAGE plperlu;
