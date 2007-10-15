-- Rule as next operation
-- authed by Yutaka Konishi
-- 2006/09/07
CREATE RULE next_ope AS ON INSERT TO operation_logs
WHERE NEW.ent_operation_id = '1'
DO select next(NEW.user_id,NEW.ent_seq_id,NEW.dis_code);
