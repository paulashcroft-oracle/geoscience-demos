-- Submit this complete single block in the owning CODEX SQL Commands session
-- only after the AIDEMODB / GEOSCIENCE checkpoint and execution window gates.
-- Tests one private temporary table and dynamic anonymous PL/SQL access only.
declare
  l_name constant varchar2(30) := 'ORA$PTT_BHC_' || substr(rawtohex(sys_guid()), 1, 16);
  l_created boolean := false;
  l_count number;
  l_error varchar2(1000);
  l_cleanup_error varchar2(1000);

  procedure cleanup is
    l_remaining number;
  begin
    if not l_created then return; end if;
    if not regexp_like(l_name, '^ORA[$]PTT_BHC_[0-9A-F]{16}$', 'c') then
      raise_application_error(-20994, 'Cleanup refused unexpected fixture name.');
    end if;
    select count(*) into l_remaining
      from user_private_temp_tables where table_name = l_name;
    if l_remaining = 1 then execute immediate 'drop table ' || l_name; end if;
    select count(*) into l_remaining
      from user_private_temp_tables where table_name = l_name;
    if l_remaining <> 0 then
      raise_application_error(-20994, 'Private fixture still exists after cleanup: ' || l_name);
    end if;
    l_created := false;
  end cleanup;
begin
  if nvl(sys_context('USERENV', 'DB_UNIQUE_NAME'), '?') <> 'tcelkxkd'
     or nvl(sys_context('USERENV', 'CURRENT_SCHEMA'), '?') <> 'GEOSCIENCE'
     or nvl(apex_custom_auth.get_security_group_id, -1) <> nvl(apex_util.find_security_group_id('GEOSCIENCE'), -2)
     or nvl(v('APP_USER'), '?') <> 'CODEX' then
    raise_application_error(-20991, 'Requires database tcelkxkd and CODEX GEOSCIENCE SQL Workshop context.');
  end if;
  if not regexp_like(l_name, '^ORA[$]PTT_BHC_[0-9A-F]{16}$', 'c') then
    raise_application_error(-20991, 'Invalid private fixture name.');
  end if;
  select count(*) into l_count from user_private_temp_tables where table_name = l_name;
  if l_count <> 0 then
    raise_application_error(-20991, 'Fixture nonce already exists; no object touched.');
  end if;

  execute immediate 'create private temporary table ' || l_name ||
    ' (probe_value number) on commit drop definition';
  l_created := true;
  -- Parsing after CREATE is essential: the inner static SQL resolves this PTT.
  execute immediate
    'declare n number; v number; begin ' ||
    'insert into ' || l_name || ' (probe_value) values (42); ' ||
    'select count(*), max(probe_value) into n, v from ' || l_name || '; ' ||
    'if n <> 1 or v is null or v <> 42 then ' ||
    'raise_application_error(-20990, ''PTT count/value assertion failed.''); ' ||
    'end if; end;';

  cleanup;
  select count(*) into l_count from user_private_temp_tables where table_name = l_name;
  if l_count <> 0 then raise_application_error(-20994, 'Fixture cleanup was not complete.'); end if;
  dbms_output.put_line('PASS: PTT creation, dynamic anonymous insert/select and cleanup verified: ' || l_name);
exception
  when others then
    l_error := substr(sqlerrm, 1, 1000);
    begin cleanup; exception when others then l_cleanup_error := substr(sqlerrm, 1, 1000); end;
    if l_cleanup_error is not null then
      raise_application_error(-20994, substr(l_error || ' CLEANUP FAILED for ' || l_name || ': ' || l_cleanup_error, 1, 2000));
    end if;
    dbms_output.put_line('FAIL: ' || l_error || '; no PTT owned by this call remains: ' || l_name);
    raise;
end;
