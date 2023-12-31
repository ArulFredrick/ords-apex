#!/bin/sh
# . /etc/profile.d/oracle_env.sh
export   CONTAINER_NAME="pdb1"
export   APEX_ARCHIVE="apex_23.1.zip"
export   APEX_DEST_LOCATION="/u01/app/oracle"
export   APEX_TABLESPACE="APEX_TABSPACE"
export   APEX_TABLESPACE_DATA_FILE="xe_apex_tabspace_01.dat"
export   APEX_PUBLIC_USER_PASSWORD="DEVdbfor_#123"
export   APEX_LISTENER_PASSWORD="DEVdbfor_#123"
export   APEX_REST_PUBLIC_USER_PASSWORD="DEVdbfor_#123"
export   APEX_ADMIN_USER="ADMIN"
export   APEX_ADMIN_USER_EMAIL_ADDRESS="saivershith.vupallancha@eappsys.com"
export   APEX_ADMIN_USER_PASSWORD="DEVdbfor_#123"
export   APEX_ADMIN_USER_PRIVILEGES="ADMIN"
export   ORACLE_USER="oracle"
export   ORACLE_GROUP="dba"
export   connection_string="sys/DEVdbfor_#123@//10.0.0.34:1521/pdb1.sub08041135160.dmvcn.oraclevcn.com"

cd $APEX_DEST_LOCATION/apex

echo "APEX Installation Script"

sudo su oracle

sqlplus /nolog <<EOF
CONNECT $connection_string as sysdba

WHENEVER SQLERROR EXIT SQL.SQLCODE;

SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF;

ALTER SESSION SET CONTAINER=$CONTAINER_NAME;
CREATE TABLESPACE $APEX_TABLESPACE DATAFILE '$APEX_TABLESPACE_DATA_FILE' SIZE 10M AUTOEXTEND ON;
@apexins.sql $APEX_TABLESPACE $APEX_TABLESPACE TEMP /i/;

-- Create the APEX Instance Administration user and set the password
BEGIN
    APEX_UTIL.SET_SECURITY_GROUP_ID( 10 );
    APEX_UTIL.CREATE_USER(
        p_user_name => '$APEX_ADMIN_USER',
        p_email_address => '$APEX_ADMIN_USER_EMAIL_ADDRESS',
        p_web_password => '$APEX_ADMIN_USER_PASSWORD',
        p_developer_privs => '$APEX_ADMIN_USER_PRIVILEGES');
    APEX_UTIL.SET_SECURITY_GROUP_ID( null );
    COMMIT;
END;
/
-- Apex REST Configuration
@apex_rest_config.sql $APEX_LISTENER_PASSWORD $APEX_REST_PUBLIC_USER_PASSWORD

-- Create a WEB_SERVICE_PROFILE if it does not exists
BEGIN
  SELECT COUNT(*) INTO PROFILE_EXISTS FROM dba_profiles WHERE profile='WEB_SERVICE_PROFILE';
  IF (PROFILE_EXISTS = 0) THEN
    EXECUTE IMMEDIATE 'CREATE PROFILE WEB_SERVICE_PROFILE LIMIT_PASSWORD_LIFE_TIME UNLIMITED';
  END IF
END;
/
-- Change the profile for the users to web_service_profile
ALTER USER apex_public_user PROFILE WEB_SERVICE_PROFILE;
ALTER USER apex_listener PROFILE WEB_SERVICE_PROFILE;
ALTER USER apex_rest_public_user PROFILE WEB_SERVICE_PROFILE;

-- Unlock the user accounts
ALTER USER apex_public_user ACCOUNT UNLOCK;
ALTER USER apex_listener ACCOUNT UNLOCK;
ALTER USER apex_rest_public_user ACCOUNT UNLOCK;

-- Change the Password for the users
ALTER USER apex_public_user IDENTIFIED BY "$APEX_PUBLIC_USER_PASSWORD";
ALTER USER apex_listener IDENTIFIED BY "$APEX_LISTENER_PASSWORD";
ALTER USER apex_rest_public_user IDENTIFIED BY $APEX_REST_PUBLIC_USER_PASSWORD;

-- Disable XDB server
-- Assumes we will use ORDS or other web listener instead
EXEC DBMS_XDB.SETHTTPPORT(0);
exec DBMS_XDB.SETHTTPPORT(0);

-- Anonymous user is not needed when we don't use XDB
ALTER USER anonymous ACCOUNT LOCK;

EXIT;
EOF
