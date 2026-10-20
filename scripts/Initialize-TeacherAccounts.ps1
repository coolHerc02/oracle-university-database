[CmdletBinding()]
param([string]$SqlPlusPath='D:\SQL\Oracle\app\oracle\product\11.2.0\server\bin\sqlplus.exe')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$credentialRoot=Join-Path $projectRoot '.local\teacher-credentials'
New-Item -ItemType Directory -Path $credentialRoot -Force | Out-Null
function Invoke-Admin([string]$Source) {
 $output=$Source | & $SqlPlusPath -L -S '/ as sysdba' 2>&1
 if ($LASTEXITCODE -ne 0) {
  $errorsOnly=@($output | ForEach-Object { [string]$_ } | Where-Object { $_ -match '^(ORA-|SP2-)' }) -join ' '
  throw ('Teacher account setup failed; passwords were not logged. '+$errorsOnly)
 }
 return ($output | Out-String)
}
$listing=Invoke-Admin @'
set echo off verify off feedback off heading off pagesize 0
whenever sqlerror exit failure rollback
select 'TEACHER_ID|'||to_char(teacher_id,'TM9') from UNIVERSITY_PROJECT.teachers order by teacher_id;
exit success
'@
foreach ($match in [regex]::Matches($listing,'TEACHER_ID\|(\d+)')) {
 $teacherId=$match.Groups[1].Value
 $login='UP_TEACHER_'+$teacherId
 if ($login.Length -gt 30 -or $login -notmatch '^UP_TEACHER_\d+$') { throw 'Invalid teacher login name.' }
 $credentialFile=Join-Path $credentialRoot ($login+'.xml')
 $exists=Invoke-Admin @"
set echo off verify off feedback off heading off pagesize 0
whenever sqlerror exit failure rollback
select 'EXISTS|'||count(*) from dba_users where username='$login';
exit success
"@
 if ($exists -match 'EXISTS\|1') {
  if (!(Test-Path -LiteralPath $credentialFile)) { throw "Login $login already exists without a project credential. It was not changed." }
 } else {
  $accountPassword='T9_'+[guid]::NewGuid().ToString('N').Substring(0,20)
  $accountCredential=[pscredential]::new($login,(ConvertTo-SecureString $accountPassword -AsPlainText -Force))
  # Save locally before creation, enabling safe retries without password resets.
  $accountCredential | Export-Clixml -LiteralPath $credentialFile
  try {
   $null=Invoke-Admin @"
set echo off verify off feedback off define off
whenever sqlerror exit failure rollback
create user $login identified by "$accountPassword";
grant create session to $login;
grant execute on UNIVERSITY_PROJECT.teacher_grading to $login;
exit success
"@
  } finally { $accountPassword=$null; $accountCredential=$null }
 }
 # Existing users must be checked too: a saved credential does not prove grants.
 $verified=Invoke-Admin @"
set echo off verify off feedback off heading off pagesize 0 serveroutput on
whenever sqlerror exit failure rollback
declare n number;
begin
 select count(*) into n from dba_role_privs where grantee='$login';
 if n<>0 then raise_application_error(-20180,'Unexpected role grants on $login.'); end if;
 select count(*) into n from dba_sys_privs where grantee='$login' and (privilege<>'CREATE SESSION' or admin_option<>'NO');
 if n<>0 then raise_application_error(-20180,'Unexpected system privileges on $login.'); end if;
 select count(*) into n from dba_sys_privs where grantee='$login' and privilege='CREATE SESSION' and admin_option='NO';
 if n<>1 then raise_application_error(-20180,'Missing login privilege on $login.'); end if;
 select count(*) into n from dba_tab_privs where grantee='$login' and
  (owner<>'UNIVERSITY_PROJECT' or table_name<>'TEACHER_GRADING' or privilege<>'EXECUTE' or grantable<>'NO');
 if n<>0 then raise_application_error(-20180,'Unexpected object privileges on $login.'); end if;
 select count(*) into n from dba_tab_privs where grantee='$login' and owner='UNIVERSITY_PROJECT' and table_name='TEACHER_GRADING' and privilege='EXECUTE' and grantable='NO';
 if n<>1 then raise_application_error(-20180,'Missing grading package privilege on $login.'); end if;
 select count(*) into n from dba_col_privs where grantee='$login';
 if n<>0 then raise_application_error(-20180,'Unexpected column privileges on $login.'); end if;
 select count(*) into n from dba_users where username='$login' and account_status='OPEN';
 if n<>1 then raise_application_error(-20180,'Account is not OPEN: $login.'); end if;
 dbms_output.put_line('MINIMAL_TEACHER_PRIVILEGES_VERIFIED');
end;
/
exit success
"@
 if ($verified -notmatch 'MINIMAL_TEACHER_PRIVILEGES_VERIFIED') { throw ('Privilege verification incomplete: '+$login) }
 Write-Output ('TEACHER_LOGIN_READY: '+$login+' (verified CREATE SESSION + EXECUTE TEACHER_GRADING only)')
}
Write-Output 'TEACHER_ACCOUNTS_READY; random passwords saved with Windows DPAPI under .local/teacher-credentials; none printed.'
