-- Geoscience 005 - Add passwordless DEMO_USER login to generated apps
--
-- AIDEMODB GEOSCIENCE is a live collaboration workspace. This script makes a
-- surgical APEX metadata change to page 9999 in app 104 and app 105; it does
-- not import or replace either application.

declare
  c_workspace_id constant number := 16120412504054324;
  c_schema       constant varchar2(30) := 'GEOSCIENCE';

  procedure add_demo_login(
    p_app_id              in number,
    p_app_label           in varchar2,
    p_region_component_id in number,
    p_process_component_id in number
  ) is
    l_region_count  number;
    l_process_count number;
    l_login_text    varchar2(32767);
    l_login_source  clob;
  begin
    l_login_text := q'~
<style>
.gs-demo-login { margin:.35rem 0 1rem; display:grid; gap:.55rem; }
.gs-demo-login__divider { display:flex; align-items:center; gap:.6rem; color:#607080; font-size:.78rem; font-weight:700; text-transform:uppercase; letter-spacing:.04em; }
.gs-demo-login__divider:before, .gs-demo-login__divider:after { content:""; height:1px; background:#d9e2ec; flex:1; }
.gs-demo-login__note { margin:0; color:#52606d; font-size:.86rem; line-height:1.45; }
</style>
<div class="gs-demo-login">
  <button class="t-Button t-Button--hot t-Button--large t-Button--stretch" type="button" onclick="apex.submit('DEMO_USER_LOGIN');">Continue as Demo User</button>
  <p class="gs-demo-login__note">For QR and shared demos. Opens the app as DEMO_USER so Geoscience activity remains visible in feedback and audit trails.</p>
  <div class="gs-demo-login__divider">or sign in</div>
</div>
~';

    dbms_lob.createtemporary(l_login_source, true);
    dbms_lob.writeappend(l_login_source, length(l_login_text), l_login_text);

    apex_application_install.set_workspace_id(c_workspace_id);
    apex_application_install.set_application_id(p_app_id);
    apex_application_install.set_schema(c_schema);

    wwv_flow_imp.import_begin(
      p_version_yyyy_mm_dd => '2024.11.30',
      p_release => '24.2.16',
      p_default_workspace_id => c_workspace_id,
      p_default_application_id => p_app_id,
      p_default_id_offset => 0,
      p_default_owner => c_schema
    );

    select count(*)
      into l_region_count
      from apex_application_page_regions
     where application_id = p_app_id
       and page_id = 9999
       and region_name = 'Demo User Login';

    if l_region_count = 0 then
      wwv_flow_imp_page.create_page_plug(
        p_id => wwv_flow_imp.id(p_region_component_id),
        p_flow_id => p_app_id,
        p_page_id => 9999,
        p_plug_name => 'Demo User Login',
        p_region_name => 'demo-user-login',
        p_region_template_options => '#DEFAULT#:t-Region--removeHeader:t-Region--noBorder:t-Region--noPadding',
        p_plug_display_sequence => 5,
        p_plug_display_point => 'BODY',
        p_plug_source => l_login_source,
        p_plug_source_type => 'NATIVE_STATIC',
        p_attributes => wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
          'expand_shortcuts', 'N',
          'output_as', 'HTML',
          'show_line_breaks', 'Y'
        )).to_clob
      );
    end if;

    select count(*)
      into l_process_count
      from apex_application_page_proc
     where application_id = p_app_id
       and page_id = 9999
       and process_name = 'Demo User Login';

    if l_process_count = 0 then
      wwv_flow_imp_page.create_page_process(
        p_id => wwv_flow_imp.id(p_process_component_id),
        p_flow_id => p_app_id,
        p_flow_step_id => 9999,
        p_process_sequence => 1,
        p_process_point => 'AFTER_SUBMIT',
        p_process_type => 'NATIVE_PLSQL',
        p_process_name => 'Demo User Login',
        p_process_sql_clob => q'~
begin
  if apex_application.g_request = 'DEMO_USER_LOGIN' then
    apex_authentication.post_login(
      p_username           => 'DEMO_USER',
      p_password           => 'DEMO',
      p_uppercase_username => true
    );

    apex_util.redirect_url(apex_page.get_url(p_page => 1));
    apex_application.stop_apex_engine;
  end if;
end;
~',
        p_process_clob_language => 'PLSQL',
        p_error_display_location => 'INLINE_IN_NOTIFICATION',
        p_process_when => 'DEMO_USER_LOGIN',
        p_process_when_type => 'REQUEST_EQUALS_CONDITION'
      );
    end if;

    wwv_flow_imp.import_end(p_auto_install_sup_obj => false);
    dbms_lob.freetemporary(l_login_source);

    dbms_output.put_line('Demo User Login checked for app ' || p_app_id || ' (' || p_app_label || ').');
  end add_demo_login;
begin
  add_demo_login(
    p_app_id => 104,
    p_app_label => 'Geoscience Demos',
    p_region_component_id => 1040500000,
    p_process_component_id => 1040500001
  );

  add_demo_login(
    p_app_id => 105,
    p_app_label => 'Boreholes Demo',
    p_region_component_id => 1050500000,
    p_process_component_id => 1050500001
  );

  commit;
end;
