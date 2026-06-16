set define off

prompt Geoscience 010 - Configure Boreholes app pages

create or replace package gs_borehole_page_api as
  function home_html return clob;
  function explorer_html return clob;
  function refresh_html return clob;
  function assistant_html return clob;
end gs_borehole_page_api;
/

create or replace package body gs_borehole_page_api as
  procedure append_text(p_clob in out nocopy clob, p_text in varchar2) is
  begin
    if p_text is not null then
      dbms_lob.writeappend(p_clob, length(p_text), p_text);
    end if;
  end append_text;

  procedure append_line(p_clob in out nocopy clob, p_text in varchar2 default null) is
  begin
    append_text(p_clob, p_text || chr(10));
  end append_line;

  function h(p_value in varchar2) return varchar2 is
  begin
    return apex_escape.html(p_value);
  end h;

  function ha(p_value in varchar2) return varchar2 is
  begin
    return apex_escape.html_attribute(p_value);
  end ha;

  function page_url(p_page in number) return varchar2 is
  begin
    return apex_util.prepare_url('f?p=' || v('APP_ID') || ':' || p_page || ':' || v('APP_SESSION') || ':::::');
  end page_url;

  procedure append_css(p_html in out nocopy clob) is
  begin
    append_line(p_html, '<style>');
    append_line(p_html, '.gs-bore{--ink:#18212f;--muted:#5d6876;--line:#d7dde5;--soft:#f6f8fb;--blue:#1d6fa5;--green:#2f7d57;--gold:#b7791f;color:var(--ink)}');
    append_line(p_html, '.gs-bore a{color:var(--blue)}.gs-bore h1{font-size:clamp(2rem,4vw,3.8rem);line-height:1.05;margin:.2rem 0 .6rem}.gs-bore h2{font-size:1.45rem;margin:.2rem 0 .7rem}.gs-bore p{color:var(--muted);line-height:1.55}.gs-bore-kicker{font-size:.78rem;text-transform:uppercase;font-weight:850;color:var(--green);letter-spacing:.08em}.gs-bore-hero{display:grid;grid-template-columns:minmax(0,1.05fr) minmax(18rem,.95fr);gap:clamp(1rem,3vw,2.4rem);align-items:center;min-height:min(62vh,40rem);padding:clamp(1rem,3vw,2rem) 0;border-bottom:1px solid var(--line)}');
    append_line(p_html, '.gs-bore-actions{display:flex;flex-wrap:wrap;gap:.7rem;margin-top:1rem}.gs-bore-btn{display:inline-flex;align-items:center;gap:.45rem;border:1px solid var(--line);border-radius:8px;background:#fff;color:var(--ink);font-weight:800;padding:.65rem .85rem;text-decoration:none}.gs-bore-btn--primary{background:var(--blue);border-color:var(--blue);color:white}.gs-bore-btn:hover{text-decoration:none;transform:translateY(-1px)}');
    append_line(p_html, '.gs-bore-stats{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.75rem;margin:1rem 0}.gs-bore-stats div{border:1px solid var(--line);border-radius:8px;background:#fff;padding:.85rem}.gs-bore-stats span{display:block;color:var(--muted);font-size:.74rem;text-transform:uppercase;font-weight:850}.gs-bore-stats strong{display:block;font-size:1.55rem;margin-top:.2rem}.gs-bore-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:1rem;margin-top:1rem}.gs-bore-panel{border:1px solid var(--line);border-radius:8px;background:#fff;padding:1rem}.gs-bore-panel h3{margin:.1rem 0 .45rem;font-size:1rem}');
    append_line(p_html, '.gs-bore-map{border:1px solid var(--line);border-radius:8px;background:linear-gradient(180deg,#f8fbfd,#eef6f1);min-height:20rem;overflow:hidden}.gs-bore-map svg{width:100%;height:auto;display:block}.gs-bore-layout{display:grid;grid-template-columns:minmax(18rem,.42fr) minmax(0,1fr);gap:1rem}.gs-bore-form{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.6rem}.gs-bore-form label{display:grid;gap:.25rem;font-weight:800;font-size:.82rem;color:var(--muted)}.gs-bore-form input,.gs-bore-form select,.gs-bore-form textarea{width:100%;border:1px solid var(--line);border-radius:8px;padding:.55rem .65rem;font:inherit;background:#fff}.gs-bore-form textarea{min-height:7rem;resize:vertical}.gs-bore-span{grid-column:1/-1}');
    append_line(p_html, '.gs-bore-table-wrap{overflow:auto;border:1px solid var(--line);border-radius:8px}.gs-bore-table{width:100%;border-collapse:collapse;background:#fff}.gs-bore-table th,.gs-bore-table td{padding:.55rem .65rem;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}.gs-bore-table th{font-size:.75rem;text-transform:uppercase;color:var(--muted);background:#f7fafc}.gs-bore-chip{display:inline-flex;border-radius:999px;background:#eef7f1;color:#276749;padding:.12rem .45rem;font-weight:850;font-size:.75rem}.gs-bore-thread{border:1px solid var(--line);border-radius:8px;background:var(--soft);padding:1rem;min-height:24rem;max-height:58vh;overflow:auto}.gs-bore-msg{background:#fff;border:1px solid var(--line);border-radius:8px;padding:1rem;margin-bottom:.8rem}.gs-bore-msg--user{background:#eaf4fb;margin-left:auto;max-width:80%}.gs-bore-label{font-size:.72rem;text-transform:uppercase;font-weight:850;color:var(--muted);margin-bottom:.35rem}.gs-bore-answer-head{border-left:4px solid var(--green);padding-left:.8rem}.gs-bore-mode{display:inline-flex;border-radius:999px;background:#edf7ff;color:#1d5d86;padding:.15rem .5rem;font-weight:850;font-size:.72rem;text-transform:uppercase}');
    append_line(p_html, '@media(max-width:800px){.gs-bore-hero,.gs-bore-layout,.gs-bore-grid,.gs-bore-stats{grid-template-columns:1fr}.gs-bore-form{grid-template-columns:1fr}.gs-bore-msg--user{max-width:100%}}');
    append_line(p_html, '</style>');
  end append_css;

  procedure append_map(p_html in out nocopy clob) is
    l_min_lon number;
    l_max_lon number;
    l_min_lat number;
    l_max_lat number;
    l_x number;
    l_y number;
  begin
    select min(longitude), max(longitude), min(latitude), max(latitude)
      into l_min_lon, l_max_lon, l_min_lat, l_max_lat
      from gs_boreholes
     where latitude is not null
       and longitude is not null;

    append_line(p_html, '<div class="gs-bore-map"><svg viewBox="0 0 720 430" role="img" aria-label="Loaded boreholes map plot">');
    append_line(p_html, '<rect width="720" height="430" fill="#f8fbfd"/><path d="M50 348C142 268 214 318 291 241c82-82 159-28 241-112 42-43 86-53 138-26v327H50z" fill="#e7f2e8" stroke="#c7dcc9"/>');
    append_line(p_html, '<g fill="none" stroke="#d3dce6" stroke-width="1">');
    for i in 1 .. 5 loop
      append_line(p_html, '<path d="M60 ' || to_char(60 + i * 60) || 'H680"/><path d="M' || to_char(70 + i * 100) || ' 35V395"/>');
    end loop;
    append_line(p_html, '</g><g>');

    for r in (
      select borehole_ref, borehole_name, latitude, longitude, depth_metres, state_code
        from gs_boreholes
       where latitude is not null
         and longitude is not null
       order by updated_at desc
       fetch first 120 rows only
    ) loop
      l_x := 60 + ((r.longitude - l_min_lon) / greatest(l_max_lon - l_min_lon, .0001)) * 600;
      l_y := 370 - ((r.latitude - l_min_lat) / greatest(l_max_lat - l_min_lat, .0001)) * 310;
      append_line(p_html, '<circle cx="' || to_char(round(l_x, 1), 'FM9990D0', 'NLS_NUMERIC_CHARACTERS=.,') ||
                          '" cy="' || to_char(round(l_y, 1), 'FM9990D0', 'NLS_NUMERIC_CHARACTERS=.,') ||
                          '" r="5" fill="#1d6fa5" opacity=".82"><title>' ||
                          h(r.borehole_name || ' (' || r.borehole_ref || ') ' || r.state_code || ' ' || r.depth_metres || 'm') ||
                          '</title></circle>');
    end loop;

    append_line(p_html, '</g><text x="60" y="405" fill="#5d6876" font-size="13">Longitude ' || h(to_char(round(l_min_lon, 2))) || ' to ' || h(to_char(round(l_max_lon, 2))) || ', latitude ' || h(to_char(round(l_min_lat, 2))) || ' to ' || h(to_char(round(l_max_lat, 2))) || '</text>');
    append_line(p_html, '</svg></div>');
  exception
    when others then
      append_line(p_html, '<div class="gs-bore-map"><p style="padding:1rem">No coordinate-bearing boreholes are loaded yet.</p></div>');
  end append_map;

  procedure append_model_options(p_html in out nocopy clob) is
  begin
    for r in (
      select remote_server_static_id, remote_server_name
        from apex_workspace_ai_services
       where provider_type_code = 'OCI_GENAI'
       order by case when remote_server_static_id = 'google_gemini_2_5_pro' then 0 else 1 end,
                lower(remote_server_name)
    ) loop
      append_line(p_html, '<option value="' || ha(r.remote_server_static_id) || '">' || h(r.remote_server_name) || '</option>');
    end loop;
  end append_model_options;

  function home_html return clob is
    l_html clob;
    l_total number;
    l_wfs number;
    l_last_refresh varchar2(100);
  begin
    dbms_lob.createtemporary(l_html, true);
    select count(*), count(case when last_refresh_run_id is not null then 1 end)
      into l_total, l_wfs
      from gs_boreholes;
    select max(to_char(finished_at, 'YYYY-MM-DD HH24:MI')) into l_last_refresh from gs_data_refresh_runs where refresh_type = 'REMOTE_REFRESH' and status_code = 'SUCCESS';

    append_line(l_html, '<div class="gs-bore">');
    append_css(l_html);
    append_line(l_html, '<section class="gs-bore-hero"><div><div class="gs-bore-kicker">Geoscience Australia WFS demo</div><h1>Australian Boreholes Demo</h1><p>Explore Australian borehole data from the Geoscience Australia Boreholes WFS, refresh a bounded area, and ask an AI assistant questions grounded in the loaded dataset.</p>');
    append_line(l_html, '<div class="gs-bore-actions"><a class="gs-bore-btn gs-bore-btn--primary" href="' || page_url(2) || '">Explore Boreholes</a><a class="gs-bore-btn" href="' || page_url(4) || '">Refresh Data</a><a class="gs-bore-btn" href="' || page_url(5) || '">Ask AI</a></div>');
    append_line(l_html, '<div class="gs-bore-stats"><div><span>Total boreholes</span><strong>' || to_char(l_total, 'FM999G999G999') || '</strong></div><div><span>WFS refreshed</span><strong>' || to_char(l_wfs, 'FM999G999G999') || '</strong></div><div><span>Last refresh</span><strong>' || h(coalesce(l_last_refresh, 'Pending')) || '</strong></div></div></div>');
    append_map(l_html);
    append_line(l_html, '</section><section class="gs-bore-grid"><article class="gs-bore-panel"><h3>Real source</h3><p>Uses `https://services.ga.gov.au/gis/boreholes/ows` with feature type `bh:Boreholes` and GeoJSON output.</p></article><article class="gs-bore-panel"><h3>Refreshable area</h3><p>Authorized users can refresh by longitude/latitude bounding box and retain provenance for source URL, request URL, row count, and errors.</p></article><article class="gs-bore-panel"><h3>AI grounded</h3><p>The assistant sees loaded borehole rows, refresh provenance, current screen/pasted context, and falls back to deterministic reports if AI is unavailable.</p></article></section></div>');
    return l_html;
  end home_html;

  function explorer_html return clob is
    l_html clob;
  begin
    dbms_lob.createtemporary(l_html, true);
    append_line(l_html, '<div class="gs-bore"><h1>Boreholes Explorer</h1>');
    append_css(l_html);
    append_line(l_html, '<div class="gs-bore-actions"><a class="gs-bore-btn" href="' || page_url(1) || '">Home</a><a class="gs-bore-btn" href="' || page_url(4) || '">Refresh Area</a><a class="gs-bore-btn gs-bore-btn--primary" href="' || page_url(5) || '">Ask AI</a></div>');
    append_line(l_html, '<div class="gs-bore-layout"><div>');
    append_map(l_html);
    append_line(l_html, '</div><div class="gs-bore-table-wrap"><table class="gs-bore-table"><thead><tr><th>Ref</th><th>Name</th><th>State</th><th>Operator</th><th>Province</th><th>Length</th><th>Report</th></tr></thead><tbody>');
    for r in (
      select borehole_ref, borehole_name, state_code, operator_name, coalesce(geological_provinces, region_name) province, depth_metres, borehole_report_uri
        from gs_boreholes
       order by updated_at desc
       fetch first 75 rows only
    ) loop
      append_line(l_html, '<tr><td><code>' || h(r.borehole_ref) || '</code></td><td>' || h(r.borehole_name) || '</td><td>' || h(r.state_code) || '</td><td>' || h(r.operator_name) || '</td><td>' || h(r.province) || '</td><td>' || h(to_char(r.depth_metres)) || '</td><td>' || case when r.borehole_report_uri is not null then '<a href="' || ha(r.borehole_report_uri) || '" target="_blank" rel="noopener">Open</a>' end || '</td></tr>');
    end loop;
    append_line(l_html, '</tbody></table></div></div></div>');
    return l_html;
  end explorer_html;

  function refresh_html return clob is
    l_html clob;
  begin
    dbms_lob.createtemporary(l_html, true);
    append_line(l_html, '<div class="gs-bore"><h1>Data Refresh</h1>');
    append_css(l_html);
    append_line(l_html, '<p>Refresh boreholes from the Geoscience Australia Boreholes WFS source, feature type <code>bh:Boreholes</code>. The default area matches the first live Tanami/central Australia slice used for verification.</p>');
    append_line(l_html, '<div class="gs-bore-layout"><section class="gs-bore-panel"><div class="gs-bore-form" id="gsBoreRefreshForm"><label>Min longitude<input id="gsMinLon" type="number" step="0.000001" value="129"></label><label>Min latitude<input id="gsMinLat" type="number" step="0.000001" value="-24"></label><label>Max longitude<input id="gsMaxLon" type="number" step="0.000001" value="139"></label><label>Max latitude<input id="gsMaxLat" type="number" step="0.000001" value="-17"></label><label>Limit<input id="gsLimit" type="number" min="1" max="10000" value="250"></label><div class="gs-bore-span"><button class="gs-bore-btn gs-bore-btn--primary" type="button" id="gsRunRefresh">Run GA WFS Refresh</button></div></div><div id="gsRefreshResult" style="margin-top:1rem"></div></section>');
    append_line(l_html, '<section class="gs-bore-panel"><h2>Recent Refresh Runs</h2><div class="gs-bore-table-wrap"><table class="gs-bore-table"><thead><tr><th>Run</th><th>Status</th><th>Rows</th><th>BBOX</th><th>Finished</th></tr></thead><tbody>');
    for r in (select refresh_run_id, status_code, rows_loaded, bbox_text, finished_at from gs_data_refresh_runs order by refresh_run_id desc fetch first 8 rows only) loop
      append_line(l_html, '<tr><td>' || r.refresh_run_id || '</td><td><span class="gs-bore-chip">' || h(r.status_code) || '</span></td><td>' || r.rows_loaded || '</td><td>' || h(r.bbox_text) || '</td><td>' || h(to_char(r.finished_at, 'YYYY-MM-DD HH24:MI')) || '</td></tr>');
    end loop;
    append_line(l_html, '</tbody></table></div></section></div>');
    append_line(l_html, '<script>(function(){var b=document.getElementById("gsRunRefresh"),out=document.getElementById("gsRefreshResult");if(!b){return;}b.addEventListener("click",function(){b.disabled=true;out.innerHTML="<p>Refreshing...</p>";apex.server.process("GS_BOREHOLES_REFRESH",{x01:gsMinLon.value,x02:gsMinLat.value,x03:gsMaxLon.value,x04:gsMaxLat.value,x05:gsLimit.value},{dataType:"json"}).then(function(r){out.innerHTML=r.success?"<p><strong>Refresh complete.</strong> Run "+r.refreshRunId+"</p><p><code>"+String(r.requestUrl||"").replace(/[&<>]/g,function(c){return {\"&\":\"&amp;\",\"<\":\"&lt;\",\">\":\"&gt;\"}[c];})+"</code></p>":"<p><strong>Refresh failed.</strong> "+String(r.message||"")+"</p>";}).catch(function(e){out.innerHTML="<p><strong>Refresh failed.</strong> "+(e.message||e)+"</p>";}).finally(function(){b.disabled=false;});});})();</script></div>');
    return l_html;
  end refresh_html;

  function assistant_html return clob is
    l_html clob;
  begin
    dbms_lob.createtemporary(l_html, true);
    append_line(l_html, '<div class="gs-bore"><h1>AI Data Assistant</h1>');
    append_css(l_html);
    append_line(l_html, '<div class="gs-bore-layout"><section class="gs-bore-panel"><div class="gs-bore-form"><label class="gs-bore-span">Service / AI model<select id="gsAiModel">');
    append_model_options(l_html);
    append_line(l_html, '</select></label><label class="gs-bore-span">Ask about boreholes<textarea id="gsAiPrompt" placeholder="Ask about borehole counts, provinces, depth, reports, operators, or the current map area"></textarea></label><label class="gs-bore-span">Pasted screen/context<textarea id="gsAiContext" placeholder="Paste a screenshot OCR note, copied report rows, coordinates, or other context"></textarea></label><label class="gs-bore-span">Screenshot or file input<input id="gsAiFile" type="file" accept="image/*,.txt,.csv,.json"></label><div class="gs-bore-span"><button class="gs-bore-btn gs-bore-btn--primary" id="gsAiAsk" type="button">Ask</button></div></div></section><section><div class="gs-bore-thread" id="gsAiThread"><div class="gs-bore-msg"><div class="gs-bore-label">Boreholes Agent</div><p>Ask questions grounded in the loaded borehole data. Pasted context is sent as text. Image files are accepted as attachment context metadata in this first slice.</p></div></div></section></div>');
    append_line(l_html, '<script>(function(){function esc(v){return String(v||"").replace(/[&<>"' || '''' || ']/g,function(c){return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","' || '''' || '":"&#39;"}[c];});}function add(k,html){var t=document.getElementById("gsAiThread"),d=document.createElement("div");d.className="gs-bore-msg"+(k==="user"?" gs-bore-msg--user":"");d.innerHTML="<div class=\"gs-bore-label\">"+(k==="user"?"You":"Boreholes Agent")+"</div>"+html;t.appendChild(d);t.scrollTop=t.scrollHeight;return d;}function simpleMd(v){return "<p>"+esc(v).replace(/\\n\\n+/g,"</p><p>").replace(/\\n/g,"<br>")+"</p>";}var b=document.getElementById("gsAiAsk"),p=document.getElementById("gsAiPrompt"),m=document.getElementById("gsAiModel"),c=document.getElementById("gsAiContext"),f=document.getElementById("gsAiFile");if(!b){return;}b.addEventListener("click",function(){var q=p.value.trim();if(!q||b.disabled){return;}var ctx=c.value||"";if(f.files&&f.files[0]){ctx+="\\n\\nAttached file metadata: "+f.files[0].name+"; type "+f.files[0].type+"; bytes "+f.files[0].size+". Binary image interpretation requires a follow-up multimodal extraction path; this request includes metadata and any pasted text.";}add("user","<p>"+esc(q)+"</p>");b.disabled=true;var hold=add("agent","<p>Thinking...</p>");apex.server.process("GS_BOREHOLES_AGENT_ASK",{x01:q,x02:m.value,x03:ctx},{dataType:"json"}).then(function(r){if(!r||!r.success){hold.innerHTML="<div class=\"gs-bore-label\">Boreholes Agent</div><p>"+esc((r&&r.message)||"No response returned.")+"</p>";return;}var html=r.answerHtml||simpleMd(r.answerMarkdown||"");if(r.selectedServiceName){html="<p><strong>Model:</strong> "+esc(r.selectedServiceName)+" <span class=\"gs-bore-chip\">"+esc(r.mode)+"</span></p>"+html;}if(r.supportingHtml){html+="<details class=\"gs-bore-section\"><summary>Grounding details</summary>"+r.supportingHtml+"</details>";}hold.innerHTML="<div class=\"gs-bore-label\">Boreholes Agent</div>"+html;}).catch(function(e){hold.innerHTML="<div class=\"gs-bore-label\">Boreholes Agent</div><p>"+esc(e.message||e)+"</p>";}).finally(function(){b.disabled=false;p.focus();});});})();</script></div>');
    return l_html;
  end assistant_html;
end gs_borehole_page_api;
/

declare
  c_workspace_id    constant number := 16120412504054324;
  c_app_id          constant number := 105;
  c_schema          constant varchar2(30) := 'GEOSCIENCE';
  c_region_blank    constant number := 4501440665235496320;
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

  for existing_page in (
    select page_id
      from apex_application_pages
     where application_id = c_app_id
       and page_id in (1, 2, 4, 5)
     order by page_id desc
  ) loop
    wwv_flow_imp_page.remove_page(p_flow_id => c_app_id, p_page_id => existing_page.page_id);
  end loop;

  wwv_flow_imp_page.create_page(
    p_id => 1,
    p_name => 'Home',
    p_alias => 'HOME',
    p_step_title => 'Boreholes Demo',
    p_autocomplete_on_off => 'OFF',
    p_page_template_options => '#DEFAULT#',
    p_protection_level => 'C',
    p_page_component_map => '24'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1050100101),
    p_plug_name => 'Boreholes Home',
    p_region_name => 'gs-boreholes-home',
    p_region_template_options => '#DEFAULT#',
    p_plug_template => c_region_blank,
    p_plug_display_sequence => 10,
    p_plug_display_point => 'BODY',
    p_plug_source => 'return gs_borehole_page_api.home_html;',
    p_function_body_language => 'PLSQL',
    p_plug_source_type => 'NATIVE_DYNAMIC_CONTENT',
    p_lazy_loading => false
  );

  wwv_flow_imp_page.create_page(
    p_id => 2,
    p_name => 'Boreholes Explorer',
    p_alias => 'BOREHOLES-EXPLORER',
    p_step_title => 'Boreholes Explorer',
    p_autocomplete_on_off => 'OFF',
    p_page_template_options => '#DEFAULT#',
    p_protection_level => 'C',
    p_page_component_map => '24'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1050100201),
    p_plug_name => 'Boreholes Explorer',
    p_region_name => 'gs-boreholes-explorer',
    p_region_template_options => '#DEFAULT#',
    p_plug_template => c_region_blank,
    p_plug_display_sequence => 10,
    p_plug_display_point => 'BODY',
    p_plug_source => 'return gs_borehole_page_api.explorer_html;',
    p_function_body_language => 'PLSQL',
    p_plug_source_type => 'NATIVE_DYNAMIC_CONTENT',
    p_lazy_loading => false
  );

  wwv_flow_imp_page.create_page(
    p_id => 4,
    p_name => 'Data Refresh',
    p_alias => 'DATA-REFRESH',
    p_step_title => 'Boreholes Data Refresh',
    p_autocomplete_on_off => 'OFF',
    p_page_template_options => '#DEFAULT#',
    p_protection_level => 'C',
    p_page_component_map => '24'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1050100401),
    p_plug_name => 'Boreholes Data Refresh',
    p_region_name => 'gs-boreholes-refresh',
    p_region_template_options => '#DEFAULT#',
    p_plug_template => c_region_blank,
    p_plug_display_sequence => 10,
    p_plug_display_point => 'BODY',
    p_plug_source => 'return gs_borehole_page_api.refresh_html;',
    p_function_body_language => 'PLSQL',
    p_plug_source_type => 'NATIVE_DYNAMIC_CONTENT',
    p_lazy_loading => false
  );

  wwv_flow_imp_page.create_page_process(
    p_id => wwv_flow_imp.id(1050100402),
    p_flow_id => c_app_id,
    p_flow_step_id => 4,
    p_process_sequence => 10,
    p_process_point => 'ON_DEMAND',
    p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'GS_BOREHOLES_REFRESH',
    p_process_sql_clob => q'~
begin
  htp.prn(
    gs_borehole_refresh_api.remote_refresh_json(
      p_min_lon => to_number(apex_application.g_x01, '999999999D999999', 'NLS_NUMERIC_CHARACTERS=.,'),
      p_min_lat => to_number(apex_application.g_x02, '999999999D999999', 'NLS_NUMERIC_CHARACTERS=.,'),
      p_max_lon => to_number(apex_application.g_x03, '999999999D999999', 'NLS_NUMERIC_CHARACTERS=.,'),
      p_max_lat => to_number(apex_application.g_x04, '999999999D999999', 'NLS_NUMERIC_CHARACTERS=.,'),
      p_limit => to_number(apex_application.g_x05)
    )
  );
end;
~',
    p_process_clob_language => 'PLSQL',
    p_error_display_location => 'INLINE_IN_NOTIFICATION'
  );

  wwv_flow_imp_page.create_page(
    p_id => 5,
    p_name => 'AI Data Assistant',
    p_alias => 'AI-DATA-ASSISTANT',
    p_step_title => 'Boreholes AI Data Assistant',
    p_autocomplete_on_off => 'OFF',
    p_page_template_options => '#DEFAULT#',
    p_protection_level => 'C',
    p_page_component_map => '24'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id => wwv_flow_imp.id(1050100501),
    p_plug_name => 'Boreholes AI Data Assistant',
    p_region_name => 'gs-boreholes-ai-assistant',
    p_region_template_options => '#DEFAULT#',
    p_plug_template => c_region_blank,
    p_plug_display_sequence => 10,
    p_plug_display_point => 'BODY',
    p_plug_source => 'return gs_borehole_page_api.assistant_html;',
    p_function_body_language => 'PLSQL',
    p_plug_source_type => 'NATIVE_DYNAMIC_CONTENT',
    p_lazy_loading => false
  );

  wwv_flow_imp_page.create_page_process(
    p_id => wwv_flow_imp.id(1050100502),
    p_flow_id => c_app_id,
    p_flow_step_id => 5,
    p_process_sequence => 10,
    p_process_point => 'ON_DEMAND',
    p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'GS_BOREHOLES_AGENT_ASK',
    p_process_sql_clob => q'~
begin
  htp.prn(
    gs_borehole_agent_api.ask_json(
      p_user_prompt => apex_application.g_x01,
      p_service_static_id => apex_application.g_x02,
      p_screen_context => apex_application.g_x03
    )
  );
end;
~',
    p_process_clob_language => 'PLSQL',
    p_error_display_location => 'INLINE_IN_NOTIFICATION'
  );

  wwv_flow_imp.import_end(p_auto_install_sup_obj => false);
end;
/

prompt Geoscience 010 complete
