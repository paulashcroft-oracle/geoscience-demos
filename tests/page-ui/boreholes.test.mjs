import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import vm from 'node:vm';

// Exercise the JavaScript emitted by the package; this is not an APEX render test.
const source = readFileSync(new URL('../../database/010_create_boreholes_page_api.sql', import.meta.url), 'utf8');

class Element {
  value = '';
  disabled = false;
  readOnly = false;
  innerHTML = '';
  textContent = '';
  children = [];
  attributes = {};
  events = {};
  classList = { add() {}, toggle() {} };
  addEventListener(type, handler) { this.events[type] = handler; }
  appendChild(child) { this.children.push(child); }
  setAttribute(name, value) { this.attributes[name] = value; }
  focus() { this.focused = true; }
  click() { if (!this.disabled) { this.events.click?.({}); } }
}

function fixture(functionName, process) {
  const functionSource = source.slice(source.indexOf(`  function ${functionName} return clob is`));
  const script = functionSource.match(/q'~<script>\r?\n([\s\S]*?)<\/script><\/div>~'/)?.[1];
  assert.ok(script, `Script found in ${functionName}`);
  const elements = Object.fromEntries([
    'gsAiAsk', 'gsAiPrompt', 'gsAiModel', 'gsAiStatus', 'gsAiThread',
    'gsRunRefresh', 'gsRefreshResult', 'gsMinLon', 'gsMinLat', 'gsMaxLon', 'gsMaxLat', 'gsLimit'
  ].map(id => [id, new Element()]));
  elements.gsAiModel.value = 'google_gemini_2_5_pro';
  const calls = [];
  const context = vm.createContext({
    document: {
      body: new Element(),
      getElementById: id => elements[id],
      createElement: () => new Element()
    },
    apex: { server: { process: (...args) => { calls.push(args); return process(...args); } } },
    Promise
  });
  new vm.Script(script, { filename: `${functionName}.js` }).runInContext(context);
  return { elements, calls, lastAnswer: () => elements.gsAiThread.children.at(-1)?.innerHTML };
}

function deferred() {
  const callbacks = {};
  return {
    done(fn) { callbacks.done = fn; return this; },
    fail(fn) { callbacks.fail = fn; return this; },
    always(fn) { callbacks.always = fn; return this; },
    resolve(value) { callbacks.done(value); callbacks.always(); },
    reject(error) { callbacks.fail(null, 'error', error); callbacks.always(); }
  };
}

const flush = () => new Promise(resolve => setImmediate(resolve));

test('UI advertises independent text questions and has no file attachment controls', () => {
  assert.match(source, /previous questions and answers are not sent/);
  assert.match(source, /files and images are not analysed/);
  assert.match(source, /maxlength="3000"/);
  for (const example of ['count boreholes in NT', 'chart count by operator', 'top 5 longest boreholes',
    'operator "NAME"', 'purpose "VALUE"', 'ref "REFERENCE"', 'summarize text:', 'explain text:']) {
    assert.ok(source.includes(`<code>${example}</code>`), `Shows accepted syntax: ${example}`);
  }
  assert.match(source, /followed by a space and your text/);
  assert.doesNotMatch(source, /gsAiFile|gsAiAttachmentList|Binary content was supplied|attachmentContext/);
});

test('one pending request prevents repeat submission and sends only the current text and model', () => {
  const pending = deferred();
  const f = fixture('assistant_html', () => pending);
  f.elements.gsAiPrompt.value = '  Count boreholes\nPasted text  ';
  f.elements.gsAiAsk.click();
  f.elements.gsAiAsk.events.click({});
  assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0][0], 'GS_BOREHOLES_AGENT_ASK');
  assert.deepEqual(Object.keys(f.calls[0][1]), ['x01', 'x02']);
  assert.equal(f.calls[0][1].x01, 'Count boreholes\nPasted text');
  assert.equal(f.elements.gsAiAsk.disabled, true);
  assert.equal(f.elements.gsAiPrompt.readOnly, true);
  assert.equal(f.elements.gsAiModel.disabled, true);
  assert.equal(f.elements.gsAiAsk.attributes['aria-busy'], 'true');
});

test('Enter submits; Shift+Enter and IME composition do not', () => {
  const f = fixture('assistant_html', () => deferred());
  f.elements.gsAiPrompt.value = 'Count boreholes';
  let prevented = 0;
  const key = extra => f.elements.gsAiPrompt.events.keydown({ key: 'Enter', preventDefault() { prevented++; }, ...extra });
  key({ shiftKey: true });
  key({ isComposing: true });
  assert.equal(f.calls.length, 0);
  key({});
  assert.equal(f.calls.length, 1);
  assert.equal(prevented, 1);
});

test('deterministic success shows its mode and timing without claiming a model was used', () => {
  const pending = deferred();
  const f = fixture('assistant_html', () => pending);
  f.elements.gsAiPrompt.value = '<img src=x onerror=bad()> count';
  f.elements.gsAiAsk.click();
  assert.match(f.elements.gsAiThread.children[0].innerHTML, /&lt;img src=x onerror=bad\(\)&gt;/);
  pending.resolve({ success: true, mode: 'DETERMINISTIC', selectedServiceName: 'Misleading model', answerHtml: '<p>255 records.</p>', requestId: 'req<&', timings: { totalMs: 12, contextMs: 0, providerMs: 0, renderMs: 2 } });
  assert.match(f.lastAnswer(), /Data answer - no AI call/);
  assert.doesNotMatch(f.lastAnswer(), /Misleading model|Model used/);
  assert.match(f.lastAnswer(), /Server: 12 ms/);
  assert.match(f.lastAnswer(), /Response preparation: 2 ms/);
  assert.match(f.lastAnswer(), /Request: req&lt;&amp;/);
  assert.equal(f.elements.gsAiPrompt.value, '');
  assert.equal(f.elements.gsAiAsk.disabled, false);
  assert.equal(f.elements.gsAiPrompt.readOnly, false);
  assert.equal(f.elements.gsAiPrompt.focused, true);
});

test('AI success labels the actual model and escapes narrative and service text', () => {
  const pending = deferred();
  const f = fixture('assistant_html', () => pending);
  f.elements.gsAiPrompt.value = 'Explain these pasted notes';
  f.elements.gsAiAsk.click();
  pending.resolve({ success: true, mode: 'APEX_AI', selectedServiceName: '<model>', answerMarkdown: '<script>bad()</script>\nText & facts' });
  assert.match(f.lastAnswer(), /Model used: &lt;model&gt;/);
  assert.match(f.lastAnswer(), /&lt;script&gt;bad\(\)&lt;\/script&gt;<br>Text &amp; facts/);
  assert.doesNotMatch(f.lastAnswer(), /<script>/);
});

test('provider fallback displays the problem and retains the exact question for retry', () => {
  const pending = deferred();
  const f = fixture('assistant_html', () => pending);
  f.elements.gsAiPrompt.value = '  Explain the loaded data  ';
  f.elements.gsAiAsk.click();
  pending.resolve({ success: true, mode: 'DETERMINISTIC_FALLBACK', selectedServiceName: 'Failed model', aiError: '<unavailable>', answerHtml: '<p>255 records.</p>' });
  assert.match(f.lastAnswer(), /Data answer - AI unavailable/);
  assert.match(f.lastAnswer(), /&lt;unavailable&gt;/);
  assert.doesNotMatch(f.lastAnswer(), /Model used|Failed model/);
  assert.equal(f.elements.gsAiPrompt.value, '  Explain the loaded data  ');
  assert.equal(f.elements.gsAiAsk.disabled, false);
});

test('clarification retains the question and announces the missing context', () => {
  const pending = deferred();
  const f = fixture('assistant_html', () => pending);
  f.elements.gsAiPrompt.value = 'What about those?';
  f.elements.gsAiAsk.click();
  pending.resolve({ success: true, mode: 'DETERMINISTIC', status: 'CLARIFICATION_REQUIRED', answerHtml: '<p>Include the record name.</p>' });
  assert.equal(f.elements.gsAiPrompt.value, 'What about those?');
  assert.match(f.elements.gsAiStatus.textContent, /More context needed/);
});

test('application and transport errors retain the prompt and release the pending state', () => {
  for (const response of ['application', 'transport']) {
    const pending = deferred();
    const f = fixture('assistant_html', () => pending);
    f.elements.gsAiPrompt.value = 'Retry me';
    f.elements.gsAiAsk.click();
    if (response === 'application') { pending.resolve({ success: false, message: '<invalid>', requestId: 'err-1' }); }
    else { pending.reject('<network error>'); }
    assert.equal(f.elements.gsAiPrompt.value, 'Retry me');
    assert.equal(f.elements.gsAiAsk.disabled, false);
    assert.match(f.lastAnswer(), /Request failed/);
    assert.doesNotMatch(f.lastAnswer(), /<invalid>|<network error>/);
  }
});

test('synchronous startup failure releases the form and preserves retry text', () => {
  const f = fixture('assistant_html', () => { throw new Error('Unavailable'); });
  f.elements.gsAiPrompt.value = 'Retry me';
  f.elements.gsAiAsk.click();
  assert.equal(f.elements.gsAiAsk.disabled, false);
  assert.equal(f.elements.gsAiPrompt.value, 'Retry me');
  assert.match(f.lastAnswer(), /Unavailable/);
});

test('native Promise responses and rejections settle the form', async () => {
  for (const fail of [false, true]) {
    const f = fixture('assistant_html', () => fail ? Promise.reject(new Error('Network')) : Promise.resolve({ success: true, mode: 'DETERMINISTIC', answerHtml: '<p>Ready.</p>' }));
    f.elements.gsAiPrompt.value = 'Question';
    f.elements.gsAiAsk.click();
    await flush();
    assert.equal(f.elements.gsAiAsk.disabled, false);
    assert.equal(f.elements.gsAiPrompt.value, fail ? 'Question' : '');
  }
});

test('refresh shows a legitimate zero-row result and returned timings without losing the panel', async () => {
  const f = fixture('refresh_html', () => Promise.resolve({ success: true, rowsLoaded: 0, emptyResult: true, refreshRunId: 8, timingMs: { download: 120, load: 0, total: 122 } }));
  f.elements.gsRunRefresh.click();
  f.elements.gsRunRefresh.events.click({});
  assert.equal(f.calls.length, 1);
  await flush();
  assert.match(f.elements.gsRefreshResult.innerHTML, /Rows loaded: 0/);
  assert.match(f.elements.gsRefreshResult.innerHTML, /Existing data is unchanged/);
  assert.match(f.elements.gsRefreshResult.innerHTML, /Download: 120 ms/);
  assert.match(f.elements.gsRefreshResult.innerHTML, /Run: 8/);
  assert.equal(f.elements.gsRunRefresh.disabled, false);
});

test('refresh errors are escaped and all controls become available for retry', async () => {
  const f = fixture('refresh_html', () => Promise.resolve({ success: false, message: '<bad GeoJSON>', refreshRunId: 9, timingMs: { total: 20 } }));
  f.elements.gsRunRefresh.click();
  await flush();
  assert.match(f.elements.gsRefreshResult.innerHTML, /&lt;bad GeoJSON&gt;/);
  assert.match(f.elements.gsRefreshResult.innerHTML, /Run: 9/);
  assert.equal(f.elements.gsRunRefresh.disabled, false);
  assert.equal(f.elements.gsMinLon.disabled, false);
});
