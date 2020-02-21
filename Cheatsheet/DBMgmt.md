**Query TableSpace **

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


    SELECT dt.tablespace_name tablespace_name,
    SUBSTR(ddf.file_name,0, instr(ddf.file_name, '/', -1, 1) - 1) AS placement_directory,
    SUBSTR(ddf.file_name, instr(ddf.file_name, '/',   -1, 1) + 1) AS file_name,
    ddf.bytes                                         /1024/1024  AS mb,
    ddf.autoextensible,
    DECODE (dt.bigfile,'NO','SMALL','YES','BIG') AS BIG_SMALL_FILE,
    dt.block_size block_size
    FROM
    (SELECT tablespace_name, file_name, bytes,autoextensible FROM dba_data_files
    UNION
     SELECT tablespace_name, file_name, bytes,autoextensible FROM dba_temp_files
    ) ddf,
    (SELECT tablespace_name, block_size,bigfile FROM dba_tablespaces
    ) dt
    WHERE dt.tablespace_name = ddf.tablespace_name
    AND dt.tablespace_name   = 'TEMP';



**change Tablespace**
    srvctl status database -thishome
    srvctl start database -db p30sdb
    sqlplus system/7xZfhC47nL3tB9rF@p30db
    ALTER TABLESPACE SYSTEM ADD DATAFILE '+P30S' SIZE 24G;
    ALTER TABLESPACE SYSAUX ADD DATAFILE '+P30S' SIZE 24G;
    ALTER TABLESPACE TEMP add tempfile '+P30S' size 31G REUSE AUTOEXTEND ON NEXT 16G MAXSIZE UNLIMITED;
    
    CREATE BIGFILE TABLESPACE IOPS DATAFILE '+P30S' SIZE 1024G AUTOEXTEND AUTOEXTEND NEXT 8G MAXSIZE UNLIMITED;

    DROP TABLESPACE IOPS INCLUDING CONTENTS AND DATAFILES;
    ALTER TABLESPACE IOPS2 RENAME TO IOPS;

**DB files**

    col tablespace_name format a16;
    col file_name format a60;
    SELECT TABLESPACE_NAME, FILE_NAME, BYTES/1024/1024 MB FROM DBA_DATA_FILES;

**Change table space size**
    col FILE_NAME format a50
    set linesize 300
    SELECT  FILE_NAME ,  BLOCKS, TABLESPACE_NAME FROM DBA_DATA_FILES;

**Query REDO LOG**

    col member format a50
    select GROUP#,TYPE,MEMBER from v$logfile;

**Manage REDO Log**

    https://logic.edchen.org/how-to-resize-redo-logs-in-oracle/

    column group# format 99999;
    column status format a10;
    column mb format 9999999;
    select group#, thread#, status, bytes/1024/1024 mb from v$log;

    alter database add logfile thread 1 group 5 ('+FRA') size 50g;
    alter database add logfile thread 1 group 6 ('+FRA') size 50g;
    alter database add logfile thread 2 group 7 ('+FRA') size 50g;
    alter database add logfile thread 2 group 8 ('+FRA') size 50g;

    alter system switch logfile;
    alter database drop logfile group x;

    col member format a50
    select GROUP#,TYPE,MEMBER from v$logfile;


**Session**

    select inst_id,count(*) from gv$session where username is not null group by inst_id;

**Memory Config**

    show parameter target
    show parameter sga
    show parameter db_file_multiblock_read_count

    alter system set sga_max_size=200G scope=spfile;
    alter system set sga_max_size=40G scope=spfile;
    alter system set sga_target=200G scope=spfile;
    alter system set sga_target=40G scope=spfile;
    alter system set sga_target=14G scope=spfile;

**MISC**

    select UserName, CREATED from all_users where UPPER(USERNAME) like 'USER%'; // check slob load progress.

**RECOVER**

    export ORACLE_SID=racdb1
    sqlplus / as sysdba
    create pfile='/tmp/p60s.ora' from spfile='+p60s/p60sdb/parameterfile/spfile.258.1031676779';

    # modify /tmp/p60s.ora to correct wrong configuration
    create spfile='+p60s/p60sdb/parameterfile/spfile.20200214' from pfile='/tmp/p60s.ora';
    startup spfile='+p60s/p60sdb/parameterfile/spfile.20200214'

**PROCESSES/SESSIONS**

    show parameter processes;
    show parameter sessions ;
    
    select count(*) from v$process;
    select count(*) from v$session;
    select count(*) from v$session where status='ACTIVE';
    select sid,serial#,username,program,machine,status from v$session;
    select value from v$parameter where name = 'processes';

    alter system set processes = 1024 scope = spfile;
    alter system set sessions = 4096 scope=spfile ;
    shutdown immediate;
    startup;

**Calibrate_IO**

    SET SERVEROUTPUT ON;
    DECLARE
    lat INTEGER;
    iops INTEGER;
    mbps INTEGER;
    BEGIN DBMS_RESOURCE_MANAGER.CALIBRATE_IO (32, 10, iops, mbps, lat);
    DBMS_OUTPUT.PUT_LINE ('Max_IOPS = ' || iops);
    DBMS_OUTPUT.PUT_LINE ('Latency = ' || lat);
    DBMS_OUTPUT.PUT_LINE ('Max_MB/s = ' || mbps);
    end;
    /