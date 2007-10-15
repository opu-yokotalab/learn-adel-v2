-- Rule as next operation
-- authed by Yutaka Konishi
-- 2006/09/07
CREATE RULE level_down_ope AS ON INSERT TO operation_logs
WHERE NEW.ent_operation_id = '3' and New.event_arg = 'down'
DO select level_down(NEW.user_id,NEW.ent_seq_id,NEW.dis_code);
