'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { once } = require('node:events');
const { createGateway, ROUTE, MAX_BYTES } = require('../../tools/sepay-webhook-gateway.cjs');

function request(port, path = ROUTE, { method = 'POST', body = 'id=1', headers = {} } = {}) {
    return new Promise((resolve, reject) => {
        const req = http.request({ hostname: '127.0.0.1', port, path, method, headers: {
            'content-type': 'application/x-www-form-urlencoded', ...headers
        } }, res => {
            const output = [];
            res.on('data', chunk => output.push(chunk));
            res.on('end', () => resolve({ status: res.statusCode, headers: res.headers,
                body: Buffer.concat(output).toString('utf8') }));
        });
        req.on('error', reject);
        req.end(body);
    });
}

test('development webhook gateway', async t => {
    let behavior;
    const calls = [];
    const upstream = http.createServer((req, res) => {
        const input = [];
        req.on('data', chunk => input.push(chunk));
        req.on('end', () => {
            calls.push({ path: req.url, headers: req.headers, body: Buffer.concat(input) });
            behavior(req, res);
        });
    });
    upstream.listen(0, '127.0.0.1');
    await once(upstream, 'listening');
    const gateway = createGateway({ upstreamPort: upstream.address().port, upstreamTimeout: 250 });
    gateway.listen(0, '127.0.0.1');
    await once(gateway, 'listening');
    const port = gateway.address().port;
    t.after(() => { gateway.closeAllConnections(); gateway.close(); upstream.closeAllConnections(); upstream.close(); });
    behavior = (_req, res) => { res.writeHead(200, { 'content-type': 'application/json' }); res.end('{"success":true}'); };

    await t.test('health is available without exposing payment readiness or secrets', async () => {
        const r = await request(port, '/healthz', { method: 'GET', body: '' });
        assert.equal(r.status, 200);
        assert.deepEqual(JSON.parse(r.body), { service: 'PharmaFlow-SePay-webhook' });
        assert.equal(calls.length, 0);
    });
    await t.test('all other routes and noncanonical webhook paths are blocked', async () => {
        for (const path of ['/', '/Pharma_Flow/products', '/Pharma_Flow/admin',
            '/Pharma_Flow/orders', `${ROUTE}?action=other`, `${ROUTE}/`, '/%50harma_Flow/payment/sepay/webhook']) {
            assert.equal((await request(port, path)).status, 404);
        }
        assert.equal(calls.length, 0);
    });
    await t.test('webhook only accepts POST', async () => {
        assert.equal((await request(port, ROUTE, { method: 'GET', body: '' })).status, 405);
        assert.equal(calls.length, 0);
    });
    await t.test('unsupported media and compressed payloads are refused', async () => {
        assert.equal((await request(port, ROUTE, { headers: { 'content-type': 'text/xml' } })).status, 415);
        assert.equal((await request(port, ROUTE, { headers: { 'content-encoding': 'gzip' } })).status, 415);
        assert.equal(calls.length, 0);
    });
    await t.test('oversized fixed-length and chunked input never reaches Tomcat', async () => {
        const body = 'x'.repeat(MAX_BYTES + 1);
        assert.equal((await request(port, ROUTE, { body, headers: { 'content-length': body.length } })).status, 413);
        assert.equal((await request(port, ROUTE, { body, headers: { 'transfer-encoding': 'chunked' } })).status, 413);
        assert.equal(calls.length, 0);
    });
    await t.test('raw bytes and signature survive; cookies and authorization do not pass through', async () => {
        const body = Buffer.from('content=PFSP123+chuy%E1%BB%83n&name=Thuốc&code=&amount=1000', 'utf8');
        const headers = { 'x-sepay-timestamp': '1234567890', 'x-sepay-signature': `sha256=${'a'.repeat(64)}`,
            cookie: 'JSESSIONID=example', authorization: 'example', 'x-forwarded-host': 'attacker.invalid' };
        const r = await request(port, ROUTE, { body, headers });
        assert.equal(r.status, 200);
        assert.equal(r.body, '{"success":true}');
        assert.equal(r.headers['cache-control'], 'no-store');
        const call = calls.at(-1);
        assert.deepEqual(call.body, body);
        assert.equal(call.path, ROUTE);
        for (const name of ['x-sepay-timestamp', 'x-sepay-signature']) assert.equal(call.headers[name], headers[name]);
        for (const name of ['cookie', 'authorization', 'x-forwarded-host']) assert.equal(call.headers[name], undefined);
    });
    await t.test('JSON is forwarded byte for byte without reserializing the signed payload', async () => {
        const body = Buffer.from('{ "id": 9007199254740993, "content": "Thuốc PFSP123", "code": null }');
        const r = await request(port, ROUTE, { body, headers: {
            'content-type': 'application/json; charset=UTF-8',
            'x-sepay-timestamp': '1234567890', 'x-sepay-signature': `sha256=${'b'.repeat(64)}`
        } });
        assert.equal(r.status, 200);
        assert.deepEqual(calls.at(-1).body, body);
        assert.equal(calls.at(-1).headers['content-type'], 'application/json; charset=UTF-8');
        assert.equal(calls.at(-1).headers['x-sepay-signature'], `sha256=${'b'.repeat(64)}`);
    });
    await t.test('authentication failures and unconfigured servlet remain failures', async () => {
        for (const status of [401, 403, 503]) {
            behavior = (_req, res) => { res.writeHead(status, { 'content-type': 'application/json' }); res.end('{"success":false}'); };
            assert.equal((await request(port)).status, status);
        }
    });
    await t.test('Tomcat HTML, redirects and response cookies are not exposed', async () => {
        behavior = (_req, res) => { res.writeHead(302, { location: '/admin', 'set-cookie': 'secret', 'content-type': 'text/html' }); res.end('<b>private</b>'); };
        const r = await request(port);
        assert.equal(r.status, 502);
        assert.equal(r.body, '{"success":false}');
        assert.equal(r.headers['set-cookie'], undefined);
        assert.equal(r.headers.location, undefined);
    });
    await t.test('malformed and excessive upstream output is refused', async () => {
        for (const body of ['null', '{"success":"true"}', 'bad-json', 'x'.repeat(MAX_BYTES + 1)]) {
            behavior = (_req, res) => { res.writeHead(200, { 'content-type': 'application/json' }); res.end(body); };
            assert.equal((await request(port)).status, 502);
        }
    });
    await t.test('unresponsive upstream fails within the deadline', async () => {
        behavior = () => {};
        assert.equal((await request(port)).status, 503);
    });
    await t.test('stopped Tomcat reports failure so SePay can retry', async () => {
        upstream.closeAllConnections();
        await new Promise(resolve => upstream.close(resolve));
        assert.equal((await request(port)).status, 503);
    });
});
