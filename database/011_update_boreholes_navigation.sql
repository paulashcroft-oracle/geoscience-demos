set define off

prompt Geoscience 011 - Update Boreholes navigation

declare
  c_workspace_id        constant number := 16120412504054324;
  c_app_id              constant number := 105;
  c_schema              constant varchar2(30) := 'GEOSCIENCE';
  c_navigation_list_id  constant number := 16345769667978244;
  c_page_nav_list_id    constant number := 16410243530978477;
  c_home_item_id        constant number := 16360105956978268;
  c_explore_item_id     constant number := 16361679480978271;
  c_admin_item_id       constant number := 16542516957979193;

  c_reports_nav_item_id constant number := 1050110101;
  c_refresh_nav_item_id constant number := 1050110102;
  c_ask_ai_nav_item_id  constant number := 1050110103;

  c_reports_card_id     constant number := 1050110201;
  c_refresh_card_id     constant number := 1050110202;
  c_ask_ai_card_id      constant number := 1050110203;

  function target_for_page(p_page_id in number) return varchar2 is
  begin
    return 'f?p=&APP_ID.:' || p_page_id || ':&APP_SESSION.::&DEBUG.:::';
  end target_for_page;

  function list_entry_id_for_page(
    p_list_id in number,
    p_page_id in number
  ) return number is
    l_id number;
  begin
    select min(list_entry_id)
      into l_id
      from apex_application_list_entries
     where application_id = c_app_id
       and list_id = p_list_id
       and entry_target like 'f?p=&APP_ID.:' || p_page_id || ':%';

    return l_id;
  end list_entry_id_for_page;

  procedure update_item(
    p_item_id  in number,
    p_label    in varchar2,
    p_page_id  in number,
    p_sequence in number
  ) is
  begin
    if p_item_id is null then
      return;
    end if;

    wwv_flow_imp_shared.set_list_item_link_text(
      p_id => p_item_id,
      p_link_text => p_label
    );

    wwv_flow_imp_shared.set_list_item_link_target(
      p_id => p_item_id,
      p_link_target => target_for_page(p_page_id)
    );

    wwv_flow_imp_shared.set_list_item_sequence(
      p_id => p_item_id,
      p_item_sequence => p_sequence
    );
  end update_item;

  procedure ensure_item(
    p_list_id    in number,
    p_page_id    in number,
    p_new_id     in number,
    p_label      in varchar2,
    p_sequence   in number,
    p_icon       in varchar2,
    p_existing_id in number default null
  ) is
    l_item_id number := coalesce(p_existing_id, list_entry_id_for_page(p_list_id, p_page_id));
  begin
    if l_item_id is null then
      wwv_flow_imp_shared.create_list_item(
        p_id => wwv_flow_imp.id(p_new_id),
        p_list_id => p_list_id,
        p_list_item_display_sequence => p_sequence,
        p_list_item_link_text => p_label,
        p_list_item_link_target => target_for_page(p_page_id),
        p_list_item_icon => p_icon,
        p_list_item_current_type => 'TARGET_PAGE'
      );
    else
      update_item(
        p_item_id => l_item_id,
        p_label => p_label,
        p_page_id => p_page_id,
        p_sequence => p_sequence
      );
    end if;
  end ensure_item;
begin
  apex_application_install.set_workspace_id(c_workspace_id);
  apex_application_install.set_application_id(c_app_id);
  apex_application_install.set_schema(c_schema);

  wwv_flow_imp.import_begin(
    p_version_yyyy_mm_dd => '2024.11.30',
    p_release => '24.2.16',
    p_default_workspace_id => c_workspace_id,
    p_default_application_id => c_app_id,
    p_default_id_offset => 0,
    p_default_owner => c_schema
  );

  update_item(
    p_item_id => c_home_item_id,
    p_label => 'Home',
    p_page_id => 1,
    p_sequence => 10
  );

  update_item(
    p_item_id => c_explore_item_id,
    p_label => 'Explore Data',
    p_page_id => 2,
    p_sequence => 20
  );

  ensure_item(
    p_list_id => c_navigation_list_id,
    p_page_id => 6,
    p_new_id => c_reports_nav_item_id,
    p_label => 'Reports',
    p_sequence => 30,
    p_icon => 'fa-bar-chart'
  );

  ensure_item(
    p_list_id => c_navigation_list_id,
    p_page_id => 4,
    p_new_id => c_refresh_nav_item_id,
    p_label => 'Refresh Data',
    p_sequence => 40,
    p_icon => 'fa-refresh'
  );

  ensure_item(
    p_list_id => c_navigation_list_id,
    p_page_id => 5,
    p_new_id => c_ask_ai_nav_item_id,
    p_label => 'Ask AI',
    p_sequence => 50,
    p_icon => 'fa-comments-o'
  );

  update_item(
    p_item_id => c_admin_item_id,
    p_label => 'Administration',
    p_page_id => 10000,
    p_sequence => 10000
  );

  ensure_item(
    p_list_id => c_page_nav_list_id,
    p_page_id => 2,
    p_new_id => 1050110200,
    p_label => 'Explore Data',
    p_sequence => 10,
    p_icon => 'fa-table'
  );

  ensure_item(
    p_list_id => c_page_nav_list_id,
    p_page_id => 6,
    p_new_id => c_reports_card_id,
    p_label => 'Reports',
    p_sequence => 20,
    p_icon => 'fa-bar-chart'
  );

  ensure_item(
    p_list_id => c_page_nav_list_id,
    p_page_id => 4,
    p_new_id => c_refresh_card_id,
    p_label => 'Refresh Data',
    p_sequence => 30,
    p_icon => 'fa-refresh'
  );

  ensure_item(
    p_list_id => c_page_nav_list_id,
    p_page_id => 5,
    p_new_id => c_ask_ai_card_id,
    p_label => 'Ask AI',
    p_sequence => 40,
    p_icon => 'fa-comments-o'
  );

  wwv_flow_imp.import_end(p_auto_install_sup_obj => false);
end;
/

prompt Geoscience 011 complete
