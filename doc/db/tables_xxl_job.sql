--
-- XXL-JOB v2.1.0
-- Copyright (c) 2015-present, xuxueli, timbo.

-- PLEASE CREATE DATABASE AT FIRST

---------------------
-- FUNCTION
CREATE OR REPLACE FUNCTION update_modified_column()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.modified = now();
    RETURN NEW;
END;
$$ language 'plpgsql';


---------------------
-- TABLE XXL_JOB_INFO
create table XXL_JOB_INFO
(
    id                        serial primary key,
    job_group                 int              not null,
    job_cron                  varchar(128)     not null,
    job_desc                  varchar(255)     not null,
    add_time                  timestamp,
    update_time               timestamp,
    author                    varchar(64),
    alarm_email               varchar(255),
    executor_route_strategy   varchar(50),
    executor_handler          varchar(255),
    executor_param            varchar(512),
    executor_block_strategy   varchar(50),
    executor_timeout          int    default 0 not null,
    executor_fail_retry_count int    default 0 not null,
    glue_type                 varchar(50)      not null,
    glue_source               text,
    glue_remark               varchar(128),
    glue_updatetime           timestamp,
    child_jobid               varchar(255),
    trigger_status            int4   default 0 not null,
    trigger_last_time         bigint default 0 not null,
    trigger_next_time         bigint default 0 not null
);

comment on column XXL_JOB_INFO.job_group is '执行器主键ID';
comment on column XXL_JOB_INFO.job_cron is '任务执行CRON';
comment on column XXL_JOB_INFO.author is '作者';
comment on column XXL_JOB_INFO.alarm_email is '报警邮件';
comment on column XXL_JOB_INFO.executor_route_strategy is '执行器路由策略';
comment on column XXL_JOB_INFO.executor_handler is '执行器任务handler';
comment on column XXL_JOB_INFO.executor_param is '任务器执行参数';
comment on column XXL_JOB_INFO.executor_block_strategy is '阻塞处理策略';
comment on column XXL_JOB_INFO.executor_timeout is '任务执行超时时间，单位秒';
comment on column XXL_JOB_INFO.executor_fail_retry_count is '失败重试次数';
comment on column XXL_JOB_INFO.glue_type is 'GLUE类型';
comment on column XXL_JOB_INFO.glue_source is 'GLUE源代码';
comment on column XXL_JOB_INFO.glue_remark is 'GLUE备注';
comment on column XXL_JOB_INFO.glue_updatetime is 'GLUE更新时间';
comment on column XXL_JOB_INFO.child_jobid is '子任务ID，多个逗号分隔';
comment on column XXL_JOB_INFO.trigger_status is '调度状态：0-停止，1-运行';
comment on column XXL_JOB_INFO.trigger_last_time is '上次调度时间';
comment on column XXL_JOB_INFO.trigger_next_time is '下次调度时间';


---------------------
-- TABLE XXL_JOB_LOG
create table XXL_JOB_LOG
(
    id                        bigserial primary key,
    job_group                 int            not null,
    job_id                    int            not null,
    executor_address          varchar(255),
    executor_handler          varchar(255),
    executor_param            varchar(512),
    executor_sharding_param   varchar(20),
    executor_fail_retry_count int  default 0 not null,
    trigger_time              timestamp,
    trigger_code              int            not null,
    trigger_msg               text,
    handle_time               timestamp,
    handle_code               int            not null,
    handle_msg                text,
    alarm_status              int4 default 0 not null
);

comment on column XXL_JOB_LOG.job_group is '执行器主键ID';
comment on column XXL_JOB_LOG.job_id is '任务，主键ID';
comment on column XXL_JOB_LOG.executor_address is '执行器地址，本次执行的地址';
comment on column XXL_JOB_LOG.executor_handler is '执行器任务handler';
comment on column XXL_JOB_LOG.executor_param is '执行器任务参数';
comment on column XXL_JOB_LOG.executor_sharding_param is '执行器任务分片参数，格式如 1/2';
comment on column XXL_JOB_LOG.executor_fail_retry_count is '失败重试次数';
comment on column XXL_JOB_LOG.trigger_time is '调度-时间';
comment on column XXL_JOB_LOG.trigger_code is '调度-结果';
comment on column XXL_JOB_LOG.trigger_msg is '调度-日志';
comment on column XXL_JOB_LOG.handle_time is '执行-时间';
comment on column XXL_JOB_LOG.handle_code is '执行-状态';
comment on column XXL_JOB_LOG.handle_msg is '执行-日志';
comment on column XXL_JOB_LOG.alarm_status is '告警状态：0-默认、1-无需告警、2-告警成功、3-告警失败';

create index XXL_JOB_LOG__I__HANDLE_CODE
    on XXL_JOB_LOG (handle_code);
create index XXL_JOB_LOG__I__TRIGGER_TIME
    on XXL_JOB_LOG (trigger_time);


---------------------
-- TABLE XXL_JOB_LOGGLUE
create table XXL_JOB_LOGGLUE
(
    id          serial primary key,
    job_id      int          not null,
    glue_type   varchar(50),
    glue_source text,
    glue_remark varchar(128) not null,
    add_time    timestamp,
    update_time timestamp
);

comment on column XXL_JOB_LOGGLUE.job_id is '任务，主键ID';
comment on column XXL_JOB_LOGGLUE.glue_type is 'GLUE类型';
comment on column XXL_JOB_LOGGLUE.glue_source is 'GLUE源代码';
comment on column XXL_JOB_LOGGLUE.glue_remark is 'GLUE备注';

CREATE TRIGGER update_logglue_modtime
    BEFORE UPDATE
    ON xxl_job_logglue
    FOR EACH ROW
EXECUTE PROCEDURE update_modified_column();

---------------------
-- TABLE XXL_JOB_REGISTRY
create table XXL_JOB_REGISTRY
(
    id             serial primary key,
    registry_group varchar(255)            not null,
    registry_key   varchar(255)            not null,
    registry_value varchar(255)            not null,
    update_time    timestamp default now() not null
);

create index XXL_JOB_REGISTRY__IC__G_K_V
    on XXL_JOB_REGISTRY (registry_group, registry_key, registry_value);

create index XXL_JOB_REGISTRY__I__UPDATE_TIME
    on XXL_JOB_REGISTRY (update_time);


---------------------
-- TABLE XXL_JOB_GROUP
create table XXL_JOB_GROUP
(
    id           serial primary key,
    app_name     varchar(64)    not null,
    title        varchar(12)    not null,
    "order"      int4 default 0 not null,
    address_type int4           not null,
    address_list varchar(512)
);

comment on column XXL_JOB_GROUP.app_name is '执行器AppName';
comment on column XXL_JOB_GROUP.title is '执行器名称';
comment on column XXL_JOB_GROUP."order" is '排序';
comment on column XXL_JOB_GROUP.address_type is '执行器地址类型：0=自动注册、1=手动录入';
comment on column XXL_JOB_GROUP.address_list is '执行器地址列表，多地址逗号分隔';

---------------------
-- TABLE XXL_JOB_USER
create table XXL_JOB_USER
(
    id         serial primary key,
    username   varchar(50) not null,
    password   varchar(50) not null,
    role       int4        not null,
    permission varchar(255),
    unique (username)
);

comment on column XXL_JOB_USER.username is '账号';
comment on column XXL_JOB_USER.password is '密码';
comment on column XXL_JOB_USER.role is '角色：0-普通用户、1-管理员';
comment on column XXL_JOB_USER.permission is '权限：执行器ID列表，多个逗号分割';


---------------------
-- TABLE XXL_JOB_USER
create table XXL_JOB_LOCK
(
    lock_name varchar(50) not null primary key
);

comment on column XXL_JOB_LOCK.lock_name is '锁名称';


---------------------
-- DATA
INSERT INTO xxl_job_group(id, app_name, title, "order", address_type, address_list)
VALUES (1, 'xxl-job-executor-sample', '示例执行器', 1, 0, NULL);

INSERT INTO xxl_job_info(id, job_group, job_cron, job_desc, add_time, update_time, author, alarm_email,
                         executor_route_strategy, executor_handler, executor_param, executor_block_strategy,
                         executor_timeout, executor_fail_retry_count, glue_type, glue_source,
                         glue_remark, glue_updatetime, child_jobid)
VALUES (1, 1, '0 0 0 * * ? *', '测试任务1', '2018-11-03 22:21:31', '2018-11-03 22:21:31', 'XXL', '', 'FIRST',
        'demoJobHandler', '', 'SERIAL_EXECUTION', 0, 0, 'BEAN', '', 'GLUE代码初始化', '2018-11-03 22:21:31', '');

INSERT INTO xxl_job_user (id, username, password, role, permission)
VALUES (1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', 1, NULL);

INSERT INTO xxl_job_lock (lock_name)
VALUES ('schedule_lock');

commit;

