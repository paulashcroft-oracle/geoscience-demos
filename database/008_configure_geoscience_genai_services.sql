-- Geoscience 008 - Configure standard workspace Generative AI Services
--
-- Target: AIDEMODB APEX workspace GEOSCIENCE, APEX 24.2.
-- This script creates the same OCI Generative AI workspace services used by
-- AFMA. It expects the workspace web credential genai_credentials to already
-- exist and does not store or modify credential secrets.
--
-- Operational note: in APEX SQL Commands on AIDEMODB, workspace remote server
-- rows are created immediately by wwv_imp_workspace.create_remote_server.
-- Do not wrap this script with wwv_flow_imp.import_end; that path can raise
-- WWV_FLOW_IMPORT_REMOTE_SERVERS collection errors after the rows are created.

declare
  c_workspace_id   constant number := 16120412504054324;
  c_app_id         constant number := 105;
  c_schema         constant varchar2(30) := 'GEOSCIENCE';
  c_base_url       constant varchar2(1000) := 'https://inference.generativeai.us-chicago-1.oci.oraclecloud.com';
  c_compartment_id constant varchar2(255) := 'ocid1.compartment.oc1..aaaaaaaadktw3nngmwhpv6eesplpofqhvgcij6ilcwdciunprkgchekld2dq';
  l_credential_id  number;

  function ai_attrs(
    p_model_id in varchar2
  ) return varchar2 is
  begin
    return '{' || wwv_flow.LF ||
           '  "compartmentId" : "' || c_compartment_id || '",' || wwv_flow.LF ||
           '  "servingMode" :' || wwv_flow.LF ||
           '  {' || wwv_flow.LF ||
           '    "modelId" : "' || p_model_id || '",' || wwv_flow.LF ||
           '    "servingType" : "ON_DEMAND"' || wwv_flow.LF ||
           '  }' || wwv_flow.LF ||
           '}';
  end ai_attrs;

  procedure ensure_service(
    p_id                 in number,
    p_name               in varchar2,
    p_static_id          in varchar2,
    p_builder_service_yn in varchar2 default 'N'
  ) is
    l_count number;
  begin
    select count(*)
      into l_count
      from apex_workspace_ai_services
     where upper(remote_server_static_id) = upper(p_static_id);

    if l_count = 0 then
      wwv_imp_workspace.create_remote_server(
        p_id => wwv_flow_imp.id(p_id),
        p_name => p_name,
        p_static_id => p_static_id,
        p_base_url => c_base_url,
        p_https_host => '',
        p_server_type => 'GENERATIVE_AI',
        p_ords_timezone => '',
        p_credential_id => l_credential_id,
        p_remote_sql_default_schema => '',
        p_mysql_sql_modes => '',
        p_prompt_on_install => false,
        p_ai_provider_type => 'OCI_GENAI',
        p_ai_is_builder_service => (upper(p_builder_service_yn) = 'Y'),
        p_ai_model_name => '',
        p_ai_http_headers => '',
        p_ai_attributes => ai_attrs(p_name)
      );
    end if;
  end ensure_service;
begin
  apex_application_install.set_workspace_id(c_workspace_id);
  apex_application_install.set_application_id(c_app_id);
  apex_application_install.set_schema(c_schema);

  select credential_id
    into l_credential_id
    from apex_workspace_credentials
   where static_id = 'genai_credentials'
     and credential_type_code = 'OCI';

  ensure_service(1050080101, 'google.gemini-2.5-pro', 'google_gemini_2_5_pro', 'Y');
  ensure_service(1050080102, 'google.gemini-2.5-flash', 'google_gemini_2_5_flash');
  ensure_service(1050080103, 'google.gemini-2.5-flash-lite', 'google_gemini_2_5_flash_lite');
  ensure_service(1050080104, 'xai.grok-4.20-reasoning', 'xai_grok_4_20_reasoning');
  ensure_service(1050080105, 'cohere.command-latest', 'cohere_command_latest');
  ensure_service(1050080106, 'cohere.command-plus-latest', 'cohere_command_plus_latest');
  ensure_service(1050080107, 'openai.gpt-oss-120b', 'openai_gpt_oss_120b');
  ensure_service(1050080108, 'openai.gpt-oss-20b', 'openai_gpt_oss_20b');
  ensure_service(1050080109, 'xai.grok-4.3', 'xai_grok_4_3');
end;
/
