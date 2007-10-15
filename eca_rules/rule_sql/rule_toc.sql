-- Rule as toc operation
-- authed by Yutaka Konishi
-- 2006/10/30
CREATE RULE toc_ope AS ON INSERT TO operation_logs
WHERE NEW.ent_operation_id = '2'
DO select toc(NEW.user_id,NEW.ent_seq_id,NEW.dis_code,New.event_arg);
