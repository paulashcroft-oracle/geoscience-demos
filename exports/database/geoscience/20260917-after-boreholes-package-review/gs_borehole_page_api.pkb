CREATE OR REPLACE package body gs_borehole_page_api as 
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
 
  function svg_num(p_value in number) return varchar2 is 
  begin 
    return to_char(round(p_value, 1), 'FM9990D0', 'NLS_NUMERIC_CHARACTERS=.,'); 
  end svg_num; 
 
  function map_x( 
    p_lon     in number, 
    p_min_lon in number, 
    p_max_lon in number, 
    p_left    in number, 
    p_width   in number 
  ) return varchar2 is 
  begin 
    return svg_num( 
      p_left + ((p_lon - p_min_lon) / greatest(p_max_lon - p_min_lon, 0.0001)) * p_width 
    ); 
  end map_x; 
 
  function map_y( 
    p_lat     in number, 
    p_min_lat in number, 
    p_max_lat in number, 
    p_top     in number, 
    p_height  in number 
  ) return varchar2 is 
  begin 
    return svg_num( 
      p_top + p_height - ((p_lat - p_min_lat) / greatest(p_max_lat - p_min_lat, 0.0001)) * p_height 
    ); 
  end map_y; 
 
  procedure append_australia_base( 
    p_html    in out nocopy clob, 
    p_min_lon in number, 
    p_max_lon in number, 
    p_min_lat in number, 
    p_max_lat in number, 
    p_left    in number, 
    p_top     in number, 
    p_width   in number, 
    p_height  in number 
  ) is 
  begin 
    append_line( 
      p_html, 
      '<path d="M ' || map_x(113.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-35.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(114.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-25.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(116.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-21.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(120.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-19.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(123.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-17.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(130.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-13.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(138.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-12.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(142.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-12.5, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(145.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-16.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(147.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-20.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(150.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-22.5, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(153.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-27.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(153.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-33.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(151.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-36.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(147.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-38.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(143.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-38.6, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(140.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-37.6, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(136.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-35.6, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(132.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-33.6, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(128.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-32.0, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(124.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-33.2, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(120.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-34.5, p_min_lat, p_max_lat, p_top, p_height) || 
      ' L ' || map_x(116.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-35.8, p_min_lat, p_max_lat, p_top, p_height) || 
      ' Z" fill="#e7f2e8" stroke="#c7dcc9" stroke-width="1.5"/>' 
    ); 
    append_line(p_html, '<g fill="none" stroke="#a9bac9" stroke-width="1.2" stroke-linecap="round">'); 
    append_line(p_html, '<path d="M ' || map_x(129.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-14.0, p_min_lat, p_max_lat, p_top, p_height) || ' L ' || map_x(129.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-35.0, p_min_lat, p_max_lat, p_top, p_height) || '"/>'); 
    append_line(p_html, '<path d="M ' || map_x(129.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-26.0, p_min_lat, p_max_lat, p_top, p_height) || ' L ' || map_x(138.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-26.0, p_min_lat, p_max_lat, p_top, p_height) || '"/>'); 
    append_line(p_html, '<path d="M ' || map_x(138.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-26.0, p_min_lat, p_max_lat, p_top, p_height) || ' L ' || map_x(138.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-11.0, p_min_lat, p_max_lat, p_top, p_height) || '"/>'); 
    append_line(p_html, '<path d="M ' || map_x(141.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-38.0, p_min_lat, p_max_lat, p_top, p_height) || ' L ' || map_x(141.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-29.0, p_min_lat, p_max_lat, p_top, p_height) || '"/>'); 
    append_line(p_html, '<path d="M ' || map_x(141.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-29.0, p_min_lat, p_max_lat, p_top, p_height) || ' L ' || map_x(153.0, p_min_lon, p_max_lon, p_left, p_width) || ' ' || map_y(-29.0, p_min_lat, p_max_lat, p_top, p_height) || '"/>'); 
    append_line(p_html, '</g>'); 
  end append_australia_base; 
 
  function page_url(p_page in number) return varchar2 is 
  begin 
    return apex_util.prepare_url('f?p=' || v('APP_ID') || ':' || p_page || ':' || v('APP_SESSION') || ':::::'); 
  end page_url; 
 
  procedure append_css(p_html in out nocopy clob) is 
  begin 
    append_line(p_html, '<style>'); 
    append_line(p_html, '.gs-bore{--ink:#18212f;--muted:#5d6876;--line:#d7dde5;--soft:#f6f8fb;--blue:#1d6fa5;--green:#2f7d57;--gold:#b7791f;color:var(--ink)}'); 
    append_line(p_html, '.gs-bore a{color:var(--blue)}.gs-bore h1{font-size:clamp(2rem,4vw,3.8rem);line-height:1.05;margin:.2rem 0 .6rem}.gs-bore h2{font-size:1.45rem;margin:.2rem 0 .7rem}.gs-bore p{color:var(--muted);line-height:1.55}.gs-bore-kicker{font-size:.78rem;text-transform:uppercase;font-weight:850;color:var(--green);letter-spacing:.08em}.gs-bore-hero{display:grid;grid-template-columns:minmax(0,1.05fr) minmax(18rem,.95fr);gap:clamp(1rem,3vw,2.4rem);align-items:center;min-height:min(62vh,40rem);padding:clamp(1rem,3vw,2rem) 0;border-bottom:1px solid var(--line)}'); 
    append_line(p_html, '.gs-bore-actions{display:flex;flex-wrap:wrap;gap:.35rem;margin-top:1rem}.gs-bore-btn{display:inline-flex;align-items:center;justify-content:center;gap:.45rem;border:1px solid var(--line);border-radius:8px;background:#fff;color:var(--ink);font-weight:800;padding:.56rem .72rem;min-height:2.6rem;text-decoration:none;white-space:nowrap;box-sizing:border-box}.gs-bore .gs-bore-btn{color:var(--blue)}.gs-bore .gs-bore-btn--primary,.gs-bore a.gs-bore-btn--primary,.gs-bore a.gs-bore-btn--primary:visited{background:var(--blue);border-color:var(--blue);color:#fff}.gs-bore-btn:hover{text-decoration:none;transform:translateY(-1px)}.gs-bore-btn[disabled]{opacity:.72;cursor:wait;transform:none}.gs-bore-btn.is-loading{position:relative;padding-left:1rem;padding-right:1rem}.gs-bore-btn.is-loading::before{content:\"\";width:.9rem;height:.9rem;border-radius:999px;border:2px solid rgba(255,255,255,.45);border-top-color:#fff;display:inline-block;animation:gs-bore-spin .8s linear infinite}.gs-bore-btn:not(.gs-bore-btn--primary).is-loading::before{border-color:rgba(29,111,165,.25);border-top-color:#1d6fa5}.gs-bore-status{border:1px solid var(--line);border-radius:8px;background:#f7fafc;padding:.75rem .85rem}.gs-bore-status strong{display:block;margin-bottom:.2rem}.gs-bore-status code{display:block;margin-top:.35rem;white-space:pre-wrap;overflow-wrap:anywhere}.gs-bore-status--working{border-left:4px solid var(--blue);background:#eef6fd}.gs-bore-status--success{border-left:4px solid var(--green);background:#eef7f1}.gs-bore-status--error{border-left:4px solid #c05621;background:#fff7ed}@keyframes gs-bore-spin{to{transform:rotate(360deg)}}'); 
    append_line(p_html, '.gs-bore-stats{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.75rem;margin:1rem 0}.gs-bore-stats div{border:1px solid var(--line);border-radius:8px;background:#fff;padding:.85rem}.gs-bore-stats span{display:block;color:var(--muted);font-size:.74rem;text-transform:uppercase;font-weight:850}.gs-bore-stats strong{display:block;font-size:1.55rem;margin-top:.2rem}.gs-bore-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:1rem;margin-top:1rem}.gs-bore-panel{border:1px solid var(--line);border-radius:8px;background:#fff;padding:1rem}.gs-bore-panel h3{margin:.1rem 0 .45rem;font-size:1rem}'); 
    append_line(p_html, '.gs-bore-map{border:1px solid var(--line);border-radius:8px;background:linear-gradient(180deg,#f8fbfd,#eef6f1);min-height:20rem;overflow:hidden}.gs-bore-map svg{width:100%;height:auto;display:block}.gs-bore-layout{display:grid;grid-template-columns:minmax(18rem,.42fr) minmax(0,1fr);gap:1rem}.gs-bore-form{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.6rem}.gs-bore-form label{display:grid;gap:.25rem;font-weight:800;font-size:.82rem;color:var(--muted)}.gs-bore-form input,.gs-bore-form select,.gs-bore-form textarea{width:100%;border:1px solid var(--line);border-radius:8px;padding:.55rem .65rem;font:inherit;background:#fff}.gs-bore-form textarea{min-height:7rem;resize:vertical}.gs-bore-span{grid-column:1/-1}'); 
    append_line(p_html, '.gs-bore-table-wrap{overflow:auto;border:1px solid var(--line);border-radius:8px}.gs-bore-table{width:100%;border-collapse:collapse;background:#fff}.gs-bore-table th,.gs-bore-table td{padding:.55rem .65rem;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}.gs-bore-table th{font-size:.75rem;text-transform:uppercase;color:var(--muted);background:#f7fafc}.gs-bore-chip{display:inline-flex;border-radius:999px;background:#eef7f1;color:#276749;padding:.12rem .45rem;font-weight:850;font-size:.75rem}.gs-bore-thread{border:1px solid var(--line);border-radius:8px;background:var(--soft);padding:1rem;min-height:24rem;max-height:58vh;overflow:auto}.gs-bore-msg{background:#fff;border:1px solid var(--line);border-radius:8px;padding:1rem;margin-bottom:.8rem}.gs-bore-msg--user{background:#eaf4fb;margin-left:auto;max-width:80%}.gs-bore-label{font-size:.72rem;text-transform:uppercase;font-weight:850;color:var(--muted);margin-bottom:.35rem}.gs-bore-answer-head{border-left:4px solid var(--green);padding-left:.8rem}.gs-bore-mode{display:inline-flex;border-radius:999px;background:#edf7ff;color:#1d5d86;padding:.15rem .5rem;font-weight:850;font-size:.72rem;text-transform:uppercase}'); 
    append_line(p_html, '.gs-bore--assistant{height:calc(100dvh - 7.5rem);min-height:38rem;display:flex;flex-direction:column;gap:.8rem}.gs-bore--assistant h1{flex:0 0 auto}.gs-bore-ai-shell{flex:1 1 auto;min-height:0;display:grid;grid-template-columns:minmax(18rem,22rem) minmax(0,1fr);gap:1rem;align-items:stretch}.gs-bore-ai-panel{min-height:0;display:flex;flex-direction:column}.gs-bore-ai-panel .gs-bore-form{height:100%;min-height:0;display:grid;grid-template-columns:1fr;grid-template-rows:auto minmax(18rem,1fr) auto auto;gap:.7rem}.gs-bore-chat-main{display:grid;grid-template-rows:auto minmax(0,1fr);min-height:0}.gs-bore-ai-panel .gs-bore-form label,.gs-bore-ai-panel .gs-bore-form textarea{min-height:0}.gs-bore-ai-panel .gs-bore-chat-main textarea{height:100%;min-height:18rem;resize:none}.gs-bore-ai-panel select,.gs-bore-ai-panel input,.gs-bore-ai-panel textarea{font-size:.95rem}.gs-bore-ai-actions{display:flex;gap:.6rem;align-items:center}.gs-bore-ai-actions .gs-bore-btn{flex:1 1 8rem;justify-content:center;min-height:2.75rem}.gs-bore-ai-output{min-height:0;display:flex}.gs-bore-ai-output .gs-bore-thread{flex:1 1 auto;height:100%;max-height:none;min-height:0}.gs-bore-ai-output .gs-bore-msg{max-width:100%}.gs-bore-ai-output .gs-bore-viz-grid{grid-template-columns:repeat(auto-fit,minmax(min(14rem,100%),1fr))}.gs-bore-ai-output .gs-bore-viz-metrics{grid-template-columns:repeat(auto-fit,minmax(min(7rem,100%),1fr))}'); 
    append_line(p_html, 'body.gs-bore-assistant-page .t-Body-contentInner,body.gs-bore-assistant-page .t-Region,body.gs-bore-assistant-page .t-Region-bodyWrap,body.gs-bore-assistant-page .t-Region-body{width:100%;max-width:none}.gs-bore--assistant,.gs-bore-ai-shell,.gs-bore-ai-output{width:100%;max-width:none;box-sizing:border-box}.gs-bore-ai-output,.gs-bore-ai-output .gs-bore-thread,.gs-bore-ai-output .gs-bore-msg,.gs-bore-ai-output .gs-bore-viz,.gs-bore-ai-output .gs-bore-viz>*,.gs-bore-ai-output .gs-bore-viz-hero,.gs-bore-ai-output .gs-bore-viz-grid,.gs-bore-ai-output .gs-bore-viz-card,.gs-bore-ai-output .gs-bore-viz-metrics,.gs-bore-ai-output .gs-bore-viz-metric,.gs-bore-ai-output .gs-bore-narrative{min-width:0;max-width:100%;width:100%;box-sizing:border-box;overflow-wrap:anywhere}.gs-bore-ai-output .gs-bore-thread{overflow-y:auto;overflow-x:hidden}.gs-bore-ai-output svg{max-width:100%;height:auto}.gs-bore-ai-output pre,.gs-bore-ai-output code{white-space:pre-wrap;overflow-wrap:anywhere}'); 
    append_line(p_html, '@media(max-width:800px){.gs-bore-hero,.gs-bore-layout,.gs-bore-grid,.gs-bore-stats{grid-template-columns:1fr}.gs-bore-form{grid-template-columns:1fr}.gs-bore-msg--user{max-width:100%}}'); 
    append_line(p_html, '@media(max-width:1024px){.gs-bore--assistant{height:auto;min-height:0}.gs-bore-ai-shell{grid-template-columns:1fr}.gs-bore-ai-panel .gs-bore-form{min-height:34rem}.gs-bore-ai-output .gs-bore-thread{min-height:32rem}.gs-bore-ai-output .gs-bore-viz-grid,.gs-bore-ai-output .gs-bore-viz-metrics{grid-template-columns:1fr}}'); 
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
    append_line(p_html, '<rect width="720" height="430" fill="#f8fbfd"/>'); 
    append_australia_base( 
      p_html => p_html, 
      p_min_lon => l_min_lon, 
      p_max_lon => l_max_lon, 
      p_min_lat => l_min_lat, 
      p_max_lat => l_max_lat, 
      p_left => 60, 
      p_top => 60, 
      p_width => 600, 
      p_height => 310 
    ); 
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
    l_found boolean := false;
  begin
    for r in ( 
      select remote_server_static_id, remote_server_name 
        from apex_workspace_ai_services 
       where provider_type_code = 'OCI_GENAI'
         and remote_server_static_id in (
           'google_gemini_2_5_pro', 'google_gemini_2_5_flash', 'cohere-command-a-03-2025'
         )
       order by case remote_server_static_id
                  when 'google_gemini_2_5_pro' then 0
                  when 'google_gemini_2_5_flash' then 1
                  else 2
                end,
                lower(remote_server_name)
    ) loop
      l_found := true;
      append_line(p_html, '<option value="' || ha(r.remote_server_static_id) || '">' || h(r.remote_server_name) || '</option>');
    end loop;
    if not l_found then
      append_line(p_html, '<option value="">AI unavailable - data answers only</option>');
    end if;
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
    append_line(l_html, '<div class="gs-bore-actions"><a class="gs-bore-btn gs-bore-btn--primary" href="' || page_url(2) || '">Explore Data</a><a class="gs-bore-btn" href="' || page_url(6) || '">Reports</a><a class="gs-bore-btn" href="' || page_url(4) || '">Refresh Data</a><a class="gs-bore-btn" href="' || page_url(5) || '">Ask AI</a></div>'); 
    append_line(l_html, '<div class="gs-bore-stats"><div><span>Total boreholes</span><strong>' || to_char(l_total, 'FM999G999G999') || '</strong></div><div><span>WFS refreshed</span><strong>' || to_char(l_wfs, 'FM999G999G999') || '</strong></div><div><span>Last refresh</span><strong>' || h(coalesce(l_last_refresh, 'Pending')) || '</strong></div></div></div>'); 
    append_map(l_html); 
    append_line(l_html, '</section><section class="gs-bore-grid"><article class="gs-bore-panel"><h3>Real source</h3><p>Uses `https://services.ga.gov.au/gis/boreholes/ows` with feature type `bh:Boreholes` and GeoJSON output.</p></article><article class="gs-bore-panel"><h3>Refreshable area</h3><p>Authorized users can refresh by longitude/latitude bounding box and retain provenance for source URL, request URL, row count, and errors.</p></article><article class="gs-bore-panel"><h3>AI grounded</h3><p>The assistant sees loaded borehole rows, refresh provenance, pasted text, and falls back to deterministic reports if AI is unavailable.</p></article></section></div>'); 
    return l_html; 
  end home_html; 
 
  function explorer_html return clob is 
    l_html clob; 
  begin 
    dbms_lob.createtemporary(l_html, true); 
    append_line(l_html, '<div class="gs-bore"><h1>Explore Data</h1>'); 
    append_css(l_html); 
    append_line(l_html, '<div class="gs-bore-actions"><a class="gs-bore-btn" href="' || page_url(1) || '">Home</a><a class="gs-bore-btn" href="' || page_url(6) || '">Reports</a><a class="gs-bore-btn" href="' || page_url(4) || '">Refresh Data</a><a class="gs-bore-btn gs-bore-btn--primary" href="' || page_url(5) || '">Ask AI</a></div>'); 
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
    append_line(l_html, '<div class="gs-bore"><h1>Refresh Data</h1>'); 
    append_css(l_html); 
    append_line(l_html, '<p>Refresh boreholes from the Geoscience Australia Boreholes WFS source, feature type <code>bh:Boreholes</code>. The default area matches the first live Tanami/central Australia slice used for verification.</p>'); 
    append_line(l_html, '<div class="gs-bore-layout"><section class="gs-bore-panel"><div class="gs-bore-form" id="gsBoreRefreshForm"><label>Min longitude<input id="gsMinLon" type="number" step="0.000001" value="129"></label><label>Min latitude<input id="gsMinLat" type="number" step="0.000001" value="-24"></label><label>Max longitude<input id="gsMaxLon" type="number" step="0.000001" value="139"></label><label>Max latitude<input id="gsMaxLat" type="number" step="0.000001" value="-17"></label><label>Limit<input id="gsLimit" type="number" min="1" max="10000" value="250"></label><div class="gs-bore-span"><button class="gs-bore-btn gs-bore-btn--primary" type="button" id="gsRunRefresh">Run GA WFS Refresh</button></div></div><div id="gsRefreshResult" role="status" aria-live="polite" aria-atomic="true" style="margin-top:1rem"></div></section>');
    append_line(l_html, '<section class="gs-bore-panel"><h2>Recent Refresh Runs</h2><p>History as of this page load. <a href="' || page_url(4) || '">Reload run history</a>.</p><div class="gs-bore-table-wrap"><table class="gs-bore-table"><thead><tr><th>Run</th><th>Status</th><th>Rows</th><th>BBOX</th><th>Finished</th></tr></thead><tbody>');
    for r in (select refresh_run_id, status_code, rows_loaded, bbox_text, finished_at from gs_data_refresh_runs order by refresh_run_id desc fetch first 8 rows only) loop 
      append_line(l_html, '<tr><td>' || r.refresh_run_id || '</td><td><span class="gs-bore-chip">' || h(r.status_code) || '</span></td><td>' || r.rows_loaded || '</td><td>' || h(r.bbox_text) || '</td><td>' || h(to_char(r.finished_at, 'YYYY-MM-DD HH24:MI')) || '</td></tr>'); 
    end loop; 
    append_line(l_html, '</tbody></table></div></section></div>'); 
    append_line(l_html, q'~<script>
(function(){
  var b = document.getElementById("gsRunRefresh");
  var out = document.getElementById("gsRefreshResult");
  var fields = ["gsMinLon", "gsMinLat", "gsMaxLon", "gsMaxLat", "gsLimit"].map(function(id){ return document.getElementById(id); });
  if (!b || !out || fields.some(function(field){ return !field; })) { return; }
  function esc(v){
    return String(v == null ? "" : v).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#39;"}[c];
    });
  }
  function setBusy(busy){
    b.disabled = busy;
    fields.forEach(function(field){ field.disabled = busy; });
    b.classList.toggle("is-loading", busy);
    b.textContent = busy ? "Refreshing GA WFS..." : "Run GA WFS Refresh";
    b.setAttribute("aria-busy", busy ? "true" : "false");
  }
  function details(r){
    var parts = [];
    if (r.refreshRunId != null) { parts.push("Run: " + r.refreshRunId); }
    var timings = r.timingMs || {};
    [["download", "Download"], ["load", "Database load"], ["total", "Server total"]].forEach(function(item){
      var value = timings[item[0]];
      if (typeof value === "number" && isFinite(value) && value >= 0) { parts.push(item[1] + ": " + value + " ms"); }
    });
    return parts.length ? "<p>" + esc(parts.join(" | ")) + "</p>" : "";
  }
  function failure(message, r){
    out.innerHTML = "<div class=\"gs-bore-status gs-bore-status--error\"><strong>Refresh failed.</strong><p>" + esc(message || "No response returned.") + "</p>" + details(r || {}) + "</div>";
  }
  b.addEventListener("click", function(){
    if (b.disabled) { return; }
    var values = fields.map(function(field){ return field.value; });
    setBusy(true);
    out.innerHTML = "<div class=\"gs-bore-status gs-bore-status--working\"><strong>Refreshing boreholes from Geoscience Australia WFS...</strong><div>BBOX: <code>" + esc(values.slice(0, 4).join(",")) + "</code></div><div>Limit: <code>" + esc(values[4]) + "</code></div></div>";
    var req;
    try {
      req = apex.server.process("GS_BOREHOLES_REFRESH", {x01:values[0], x02:values[1], x03:values[2], x04:values[3], x05:values[4]}, {dataType:"json"});
    } catch (e) {
      failure((e && e.message) || "Request could not be started.");
      setBusy(false);
      return;
    }
    Promise.resolve(req).then(function(r){
      if (!r || !r.success) { failure(r && r.message, r); return; }
      var empty = r.emptyResult === true || r.rowsLoaded === 0;
      out.innerHTML = "<div class=\"gs-bore-status gs-bore-status--success\"><strong>" + (empty ? "Refresh complete: no matching rows." : "Refresh complete.") + "</strong><p>Rows loaded: " + esc(r.rowsLoaded == null ? "not reported" : r.rowsLoaded) + "." + (empty ? " Existing data is unchanged." : "") + "</p>" + (r.message ? "<p>" + esc(r.message) + "</p>" : "") + details(r) + "<code>" + esc(r.requestUrl || "") + "</code></div>";
    }).catch(function(e){
      failure((e && e.message) || e || "Request failed.");
    }).finally(function(){ setBusy(false); });
  });
})();
</script></div>~');
    return l_html; 
  end refresh_html; 
 
  function reports_intro_html return clob is 
    l_html clob; 
  begin 
    dbms_lob.createtemporary(l_html, true); 
    append_line(l_html, '<div class="gs-bore"><h1>Reports</h1>'); 
    append_css(l_html); 
    append_line(l_html, '<div class="gs-bore-actions"><a class="gs-bore-btn" href="' || page_url(1) || '">Home</a><a class="gs-bore-btn" href="' || page_url(2) || '">Explore Data</a><a class="gs-bore-btn" href="' || page_url(4) || '">Refresh Data</a><a class="gs-bore-btn gs-bore-btn--primary" href="' || page_url(5) || '">Ask AI</a></div>'); 
    append_line(l_html, '<p>Use the interactive native APEX map to pan and zoom across Australia, then scan the supporting report cards below for state, purpose, length, and operator summaries.</p>'); 
    append_line(l_html, '</div>'); 
    return l_html; 
  end reports_intro_html; 
 
  function reports_html return clob is 
    l_html clob; 
  begin 
    dbms_lob.createtemporary(l_html, true); 
    append_line(l_html, '<div class="gs-bore">'); 
    append_css(l_html); 
    append_line(l_html, gs_borehole_agent_api.dashboard_report_html); 
    append_line(l_html, '</div>'); 
    return l_html; 
  end reports_html; 
 
  function assistant_html return clob is 
    l_html clob; 
  begin 
    dbms_lob.createtemporary(l_html, true); 
    append_line(l_html, '<div class="gs-bore gs-bore--assistant"><h1>AI Data Assistant</h1>'); 
    append_css(l_html); 
    append_line(l_html, '<div class="gs-bore-ai-shell"><section class="gs-bore-panel gs-bore-ai-panel"><div class="gs-bore-form"><label class="gs-bore-span">AI model for explanations<select id="gsAiModel">');
    append_model_options(l_html);
    append_line(l_html, q'~</select></label><label class="gs-bore-span gs-bore-chat-main">Ask about boreholes<textarea id="gsAiPrompt" maxlength="3000" aria-describedby="gsAiHelp" placeholder="Ask a data question, or use summarize text: followed by your pasted text. Enter asks; Shift+Enter adds a new line."></textarea></label><p class="gs-bore-span" id="gsAiHelp">Each question is independent; previous questions and answers are not sent. Use the example formats alongside (up to 3,000 characters). Pasted text is supported; files and images are not analysed.</p><div class="gs-bore-span gs-bore-ai-actions"><button class="t-Button t-Button--hot gs-bore-btn gs-bore-btn--primary" id="gsAiAsk" type="button">Ask</button><span id="gsAiStatus" role="status" aria-live="polite" aria-atomic="true"></span></div></div></section><section class="gs-bore-ai-output" aria-label="Recent independent questions"><div class="gs-bore-thread" id="gsAiThread"><div class="gs-bore-msg"><div class="gs-bore-label">Boreholes Assistant</div><p>Ask a complete question about the loaded borehole data. Counts, charts and map links can be answered directly from the data; explanations may use the selected AI model. This page shows recent answers for reference, without conversation memory.</p><p>Try <code>count boreholes in NT</code>, <code>chart count by operator</code> or <code>top 5 longest boreholes</code>.</p><p>Exact filters use <code>operator "NAME"</code>, <code>purpose "VALUE"</code> or <code>ref "REFERENCE"</code>; replace the quoted text with a loaded value. For pasted text, start with <code>summarize text:</code> or <code>explain text:</code>, followed by a space and your text.</p></div></div></section></div>~');
    append_line(l_html, q'~<script> 
(function(){ 
  document.body.classList.add("gs-bore-assistant-page"); 
  function esc(v){ 
    return String(v == null ? "" : v).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#39;"}[c]; 
    }); 
  } 
  function add(k, html){ 
    var t = document.getElementById("gsAiThread"); 
    var d = document.createElement("div"); 
    d.className = "gs-bore-msg" + (k === "user" ? " gs-bore-msg--user" : ""); 
    d.innerHTML = "<div class=\"gs-bore-label\">" + (k === "user" ? "You" : "Boreholes Assistant") + "</div>" + html;
    t.appendChild(d); 
    t.scrollTop = t.scrollHeight; 
    return d; 
  } 
  function simpleMd(v){ 
    return "<p>" + esc(v).replace(/\n\n+/g, "</p><p>").replace(/\n/g, "<br>") + "</p>"; 
  } 
  function setBusy(busy){
    b.disabled = busy;
    m.disabled = busy;
    p.readOnly = busy;
    b.classList.toggle("is-loading", busy);
    b.setAttribute("aria-busy", busy ? "true" : "false");
    b.textContent = busy ? "Answering..." : "Ask";
  }
  function finish(){
    setBusy(false);
    p.focus();
  }
  function responseDetails(r){
    var details = [];
    var timings = r.timings || {};
    [["totalMs", "Server"], ["contextMs", "Context"], ["providerMs", "AI provider"], ["renderMs", "Response preparation"]].forEach(function(item){
      var value = timings[item[0]];
      if (typeof value === "number" && isFinite(value) && value >= 0) {
        details.push(item[1] + ": " + value + " ms");
      }
    });
    if (r.requestId) { details.push("Request: " + r.requestId); }
    return details.length ? "<p class=\"gs-bore-response-details\">" + esc(details.join(" | ")) + "</p>" : "";
  }
  function showFailure(hold, message, r){
    status.textContent = "Request failed. Your question is retained; try again.";
    hold.innerHTML = "<div class=\"gs-bore-label\">Boreholes Assistant</div><div class=\"gs-bore-status gs-bore-status--error\"><strong>Request failed</strong><p>" + esc(message || "No response returned.") + "</p><p>Your question is retained so you can try again.</p></div>" + responseDetails(r || {});
  }
  function showResponse(hold, r){
    if (!r || !r.success) {
      showFailure(hold, r && r.message, r);
      return;
    }
    var html = r.answerHtml || simpleMd(r.answerMarkdown || "");
    var fallback = r.mode === "DETERMINISTIC_FALLBACK";
    var clarification = r.status === "CLARIFICATION_REQUIRED";
    var modeLabel = clarification ? "More context needed" : r.mode === "APEX_AI" ? "AI explanation" : fallback ? "Data answer - AI unavailable" : r.mode === "DETERMINISTIC" ? "Data answer - no AI call" : "Answer (mode not reported)";
    var summary = "<p><strong>" + esc(modeLabel) + "</strong>";
    if (r.mode === "APEX_AI" && r.selectedServiceName) {
      summary += "<br>Model used: " + esc(r.selectedServiceName);
    }
    summary += "</p>";
    if (fallback || r.aiError) {
      summary += "<div class=\"gs-bore-status gs-bore-status--error\"><strong>AI explanation unavailable</strong><p>" + esc(r.aiError || "A data answer is shown instead.") + "</p><p>Your question is retained if you want to retry.</p></div>";
    } else if (!clarification) {
      p.value = "";
    }
    status.textContent = fallback || r.aiError ? "Data answer ready. AI unavailable; your question is retained." : clarification ? "More context needed. Your question is retained." : modeLabel + " ready.";
    if (r.supportingHtml) {
      html += "<details class=\"gs-bore-section\"><summary>Grounding details</summary>" + r.supportingHtml + "</details>";
    }
    hold.innerHTML = "<div class=\"gs-bore-label\">Boreholes Assistant</div>" + summary + html + responseDetails(r);
  } 
 
  var b = document.getElementById("gsAiAsk"); 
  var p = document.getElementById("gsAiPrompt"); 
  var m = document.getElementById("gsAiModel"); 
  var status = document.getElementById("gsAiStatus");
  if (!b || !p || !m || !status) { return; }
  p.addEventListener("keydown", function(e){ 
    if (e.key === "Enter" && !e.isComposing && !e.shiftKey && !e.ctrlKey && !e.altKey && !e.metaKey) {
      e.preventDefault(); 
      b.click(); 
    } 
  }); 
  b.addEventListener("click", function(){ 
    var q = p.value.trim(); 
    if (!q || b.disabled) { return; } 
    add("user", simpleMd(q));
    setBusy(true);
    status.textContent = "Answering your question...";
    var hold = add("agent", "<p>Answering your question...</p>");
    var req;
    try {
      req = apex.server.process("GS_BOREHOLES_AGENT_ASK", {x01:q, x02:m.value}, {dataType:"json"});
    } catch (e) {
      showFailure(hold, (e && e.message) || "Request could not be started.");
      finish();
      return;
    }
    if (req && typeof req.done === "function") { 
      req.done(function(r){ showResponse(hold, r); }) 
         .fail(function(jqXHR, textStatus, errorThrown){ showFailure(hold, errorThrown || textStatus || "Request failed."); })
         .always(finish); 
    } else if (req && typeof req.then === "function") { 
      Promise.resolve(req).then(function(r){ showResponse(hold, r); }) 
        .catch(function(e){ showFailure(hold, (e && e.message) || e || "Request failed."); })
        .finally(finish); 
    } else { 
      showFailure(hold, "Request could not be started.");
      finish(); 
    } 
  }); 
})(); 
</script></div>~'); 
    return l_html; 
  end assistant_html; 
end gs_borehole_page_api;
/
