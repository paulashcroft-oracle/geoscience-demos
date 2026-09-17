CREATE OR REPLACE package gs_borehole_refresh_api as
  function wfs_request_url(
    p_min_lon in number default 129,
    p_min_lat in number default -24,
    p_max_lon in number default 139,
    p_max_lat in number default -17,
    p_limit   in number default 250
  ) return varchar2;

  function load_geojson_clob(
    p_geojson     in clob,
    p_request_url in varchar2,
    p_bbox_text   in varchar2,
    p_limit       in number,
    p_notes       in varchar2 default null
  ) return number;

  function remote_refresh_json(
    p_min_lon in number default 129,
    p_min_lat in number default -24,
    p_max_lon in number default 139,
    p_max_lat in number default -17,
    p_limit   in number default 250
  ) return clob;
end gs_borehole_refresh_api;
/
