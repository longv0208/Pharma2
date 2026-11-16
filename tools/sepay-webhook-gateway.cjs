'use strict';

// Development tunnel gateway. The Java servlet remains responsible for HMAC
// verification and payment processing. Never expose the entire Tomcat app.
const http = require('node:http');
const ROUTE = '/Pharma_Flow/payment/sepay/webhook';
const MAX_BYTES = 16384;

function json(res, status, value) {
    if (res.destroyed || res.writableEnded) return;
    res.writeHead(status, {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
        'X-Content-Type-Options': 'nosniff'
    });
    res.end(JSON.stringify(value));
}

function createGateway({ upstreamPort = 18080, upstreamTimeout = 10000 } = {}) {
    const server = http.createServer((req, res) => {
        const reject = status => { req.resume(); json(res, status, { success: false }); };
        if (req.url === '/healthz' && req.method === 'GET') {
            json(res, 200, { service: 'PharmaFlow-SePay-webhook' });
            return;
        }
        if (req.url !== ROUTE) { reject(404); return; }
        if (req.method !== 'POST') { reject(405); return; }
        if (!['application/json', 'application/x-www-form-urlencoded'].includes(
                (req.headers['content-type'] || '').split(';')[0].trim().toLowerCase())
                || !['identity', undefined].includes(req.headers['content-encoding'])) {
            reject(415); return;
        }
        if (Number(req.headers['content-length']) > MAX_BYTES) { reject(413); return; }
        let length = 0;
        let overflow = false;
        const chunks = [];
        req.on('error', () => json(res, 400, { success: false }));
        req.on('data', chunk => {
            length += chunk.length;
            if (length > MAX_BYTES) {
                overflow = true;
                chunks.length = 0;
                json(res, 413, { success: false });
            } else if (!overflow) chunks.push(chunk);
        });
        req.on('end', () => {
            if (overflow || res.writableEnded) return;
            const body = Buffer.concat(chunks);
            const headers = {
                'content-type': req.headers['content-type'],
                'content-length': body.length
            };
            for (const name of ['x-sepay-timestamp', 'x-sepay-signature']) {
                if (req.headers[name] !== undefined) headers[name] = req.headers[name];
            }
            const upstream = http.request({
                hostname: '127.0.0.1', port: upstreamPort, path: ROUTE,
                method: 'POST', headers, agent: false
            }, response => {
                let received = 0;
                const output = [];
                response.on('error', () => json(res, 502, { success: false }));
                response.on('data', chunk => {
                    received += chunk.length;
                    if (received > MAX_BYTES) {
                        json(res, 502, { success: false });
                        response.destroy();
                    } else output.push(chunk);
                });
                response.on('end', () => {
                    try {
                        const value = JSON.parse(Buffer.concat(output).toString('utf8'));
                        const status = response.statusCode;
                        if (!/^application\/json(?:;|$)/i.test(response.headers['content-type'] || '')
                                || typeof value?.success !== 'boolean'
                                || !([200, 201].includes(status) || (status >= 400 && status <= 599))) {
                            throw new Error('Unexpected upstream response');
                        }
                        json(res, status, { success: value.success });
                    } catch {
                        json(res, 502, { success: false });
                    }
                });
            });
            // A hard deadline also bounds a peer that sends bytes indefinitely.
            const deadline = setTimeout(() => upstream.destroy(new Error('Timeout')), upstreamTimeout);
            upstream.on('close', () => clearTimeout(deadline));
            upstream.on('error', () => json(res, 503, { success: false }));
            res.on('close', () => { if (!res.writableEnded) upstream.destroy(); });
            upstream.end(body); // Preserve exact bytes for timestamp.raw_body HMAC.
        });
    });
    server.maxConnections = 32;
    server.headersTimeout = 10000;
    server.requestTimeout = 15000;
    server.timeout = 20000;
    server.keepAliveTimeout = 3000;
    return server;
}

if (require.main === module) {
    const port = Number(process.env.PHARMA_WEBHOOK_PORT || 18181);
    const upstreamPort = Number(process.env.PHARMA_TOMCAT_PORT || 18080);
    if (![port, upstreamPort].every(p => Number.isInteger(p) && p >= 1024 && p <= 65535)) {
        throw new Error('Invalid local port');
    }
    const server = createGateway({ upstreamPort });
    server.listen(port, '127.0.0.1', () => process.stdout.write(`SePay gateway listening on 127.0.0.1:${port}\n`));
    for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => server.close());
}

module.exports = { createGateway, ROUTE, MAX_BYTES };
