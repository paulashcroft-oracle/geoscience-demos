CREATE OR REPLACE package gs_borehole_page_api as
  function home_html return clob;
  function explorer_html return clob;
  function refresh_html return clob;
  function reports_intro_html return clob;
  function reports_html return clob;
  function assistant_html return clob;
end gs_borehole_page_api;
/
