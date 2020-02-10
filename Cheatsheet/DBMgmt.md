**Get current Table space usage. **

    set pages 999
    set lines 400
    SELECT df.tablespace_name tablespace_name,
    max(df.autoextensible) auto_ext,
    round(df.maxbytes / (1024 * 1024), 2) max_ts_size,
    round((df.bytes - sum(fs.bytes)) / (df.maxbytes) * 100, 2) max_ts_pct_used,
    round(df.bytes / (1024 * 1024), 2) curr_ts_size,
    round((df.bytes - sum(fs.bytes)) / (1024 * 1024), 2) used_ts_size,
    round((df.bytes-sum(fs.bytes)) * 100 / df.bytes, 2) ts_pct_used,
    round(sum(fs.bytes) / (1024 * 1024), 2) free_ts_size,
    nvl(round(sum(fs.bytes) * 100 / df.bytes), 2) ts_pct_free
    FROM dba_free_space fs,
    (select tablespace_name, 
    sum(bytes) bytes,
    sum(decode(maxbytes, 0, bytes, maxbytes)) maxbytes,
    max(autoextensible) autoextensible
    from dba_data_files
    group by tablespace_name) df
    WHERE fs.tablespace_name (+) = df.tablespace_name
    GROUP BY df.tablespace_name, df.bytes, df.maxbytes
    UNION ALL
    SELECT df.tablespace_name tablespace_name,
    max(df.autoextensible) auto_ext,
    round(df.maxbytes / (1024 * 1024), 2) max_ts_size,
    round((df.bytes - sum(fs.bytes)) / (df.maxbytes) * 100, 2) max_ts_pct_used,
    round(df.bytes / (1024 * 1024), 2) curr_ts_size,
    round((df.bytes - sum(fs.bytes)) / (1024 * 1024), 2) used_ts_size,
    round((df.bytes-sum(fs.bytes)) * 100 / df.bytes, 2) ts_pct_used,
    round(sum(fs.bytes) / (1024 * 1024), 2) free_ts_size,
    nvl(round(sum(fs.bytes) * 100 / df.bytes), 2) ts_pct_free
    FROM (select tablespace_name, bytes_used bytes
    from V$temp_space_header
    group by tablespace_name, bytes_free, bytes_used) fs,
    (select tablespace_name,
    sum(bytes) bytes,
    sum(decode(maxbytes, 0, bytes, maxbytes)) maxbytes,
    max(autoextensible) autoextensible
    from dba_temp_files
    group by tablespace_name) df
    WHERE fs.tablespace_name (+) = df.tablespace_name
    GROUP BY df.tablespace_name, df.bytes, df.maxbytes
    ORDER BY 4 DESC;


**Change table space size**
    col FILE_NAME format a50
    set linesize 300
    SELECT  FILE_NAME ,  BLOCKS, TABLESPACE_NAME FROM DBA_DATA_FILES;

**Manage REDO Log**

    https://logic.edchen.org/how-to-resize-redo-logs-in-oracle/

    column group# format 99999;
    column status format a10;
    column mb format 99999;
    select group#, thread#, status, bytes/1024/1024 mb from v$log;

    alter database add logfile thread 1 group 5 ('+FRA') size 10g, group 6 ('+FRA') size 10;
    alter database add logfile thread 2 group 7 ('+FRA') size 10g, group 8 ('+FRA') size 10;

    alter system switch all logfile;
    alter database drop logfile group x;

    col member format a50
    select GROUP#,TYPE,MEMBER from v$logfile;


**Session**

    select inst_id,count(*) from gv$session where username is not null group by inst_id;

