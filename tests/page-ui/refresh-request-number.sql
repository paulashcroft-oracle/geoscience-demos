-- Exact page 4 callback helper from the callback acceptance note.
-- Anonymous assertions only: no schema objects, package calls or refresh requests.
-- Run in SQLcl with SERVEROUTPUT enabled. Failure raises ORA-20001.
set serveroutput on

declare
  l_checks pls_integer := 0;

  function request_number(p_text in varchar2) return number is
    l_text varchar2(32767) := trim(p_text);
  begin
    if l_text is null
       or not regexp_like(
         l_text,
         '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$',
         'c'
       ) then
      return null;
    end if;
    if substr(l_text, 1, 1) = '+' then
      l_text := substr(l_text, 2);
    end if;
    return to_number(
      l_text default null on conversion error,
      '999999999D999999',
      'NLS_NUMERIC_CHARACTERS=''.,'''
    );
  end request_number;

  procedure assert_number(p_label varchar2, p_text varchar2, p_expected number) is
    l_actual number := request_number(p_text);
  begin
    if (p_expected is null and l_actual is not null)
       or (p_expected is not null and (l_actual is null or l_actual <> p_expected)) then
      raise_application_error(-20001, 'request_number assertion failed: ' || p_label);
    end if;
    l_checks := l_checks + 1;
  end assert_number;
begin
  assert_number('leading decimal point', '.5', .5);
  assert_number('trailing decimal point', '1.', 1);
  assert_number('negative leading decimal point', '-.5', -.5);
  assert_number('positive leading decimal point', '+.5', .5);
  assert_number('positive trailing decimal point', '+1.', 1);
  assert_number('explicit plus', '+135.5', 135.5);
  assert_number('negative decimal', '-20.5', -20.5);
  assert_number('outer spaces with sign', '  +135.5  ', 135.5);
  assert_number('outer spaces', ' 129 ', 129);
  assert_number('six fractional digits', '-24.123456', -24.123456);
  assert_number('zero unchanged for package validation', '0', 0);
  assert_number('negative zero', '-0', 0);
  assert_number('limit ceiling', '10000', 10000);
  assert_number('integral decimal limit', '10000.0', 10000);
  assert_number('high limit unchanged for package validation', '10001', 10001);
  assert_number('fractional limit unchanged for package validation', '1.5', 1.5);
  assert_number('null input', null, null);
  assert_number('blank input', '   ', null);
  assert_number('plus alone', '+', null);
  assert_number('minus alone', '-', null);
  assert_number('point alone', '.', null);
  assert_number('signed point alone', '+.', null);
  assert_number('decimal comma', '1,5', null);
  assert_number('grouping comma', '1,000', null);
  assert_number('comma with outer spaces', ' 1,5 ', null);
  assert_number('NaN', 'NaN', null);
  assert_number('Infinity', 'Infinity', null);
  assert_number('nonnumeric', 'abc', null);
  assert_number('positive exponent', '1e3', null);
  assert_number('negative exponent', '1e-3', null);
  assert_number('excess BBOX precision', '129.1234567', null);
  assert_number('fraction must not round to valid limit', '1.0000001', null);
  assert_number('integer exceeds format width', '1000000000', null);
  assert_number('repeated sign', '--1', null);
  assert_number('embedded space', '1 5', null);
  assert_number('multiple decimal points', '1..5', null);
  dbms_output.put_line('PASS request_number assertions: ' || l_checks);
end;
/
