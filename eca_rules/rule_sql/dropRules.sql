DROP RULE level_down_ope on operation_logs;
DROP FUNCTION level_down(integer,integer,integer);

DROP RULE level_up_ope on operation_logs;
DROP FUNCTION level_up(integer,integer,integer);

DROP RULE toc_ope on operation_logs;
DROP FUNCTION toc(integer,integer,integer,varchar);

DROP RULE next_ope on operation_logs;
DROP FUNCTION next(integer,integer,integer);