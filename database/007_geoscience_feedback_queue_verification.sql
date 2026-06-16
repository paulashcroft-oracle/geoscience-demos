-- Geoscience 007 - Verify shared feedback queue foundation

select 'OBJECT' check_type,
       object_name check_name,
       object_type detail_1,
       status detail_2
  from user_objects
 where object_name in (
       'GS_AI_HUB_FEEDBACK_FORWARDS',
       'GS_AI_HUB_FEEDBACK_CANDIDATES_V',
       'GS_AI_HUB_FEEDBACK'
       )
union all
select 'PAGE_PROCESS',
       to_char(application_id) || ':10030',
       process_name,
       process_point || ' sequence ' || execution_sequence
  from apex_application_page_proc
 where application_id in (104, 105)
   and page_id = 10030
   and process_name = 'Queue AI Hub Feedback'
union all
select 'QUEUE_COUNT',
       'Candidates',
       to_char(count(*)),
       null
  from gs_ai_hub_feedback_candidates_v
union all
select 'QUEUE_COUNT',
       'Forward ledger',
       to_char(count(*)),
       null
  from gs_ai_hub_feedback_forwards
order by 1, 2;
