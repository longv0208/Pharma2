"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const source = fs.readFileSync(path.join(__dirname, "../../web/js/payment-status.js"), "utf8");

async function scenario(options = {}) {
    const timers = [];
    const redirects = [];
    const notice = { dataset: { statusUrl: "/Pharma_Flow/orders?action=payment-status&id=901" }, textContent: "waiting" };
    let now = 0;
    let requests = 0;
    let reloads = 0;
    const listTargets = options.listStatuses ? options.listStatuses.map((status, index) => ({
        dataset: { paymentStatusUrl: "/Pharma_Flow/orders?action=payment-status&id=" + (901 + index) }, status
    })) : [];
    const context = {
        document: {
            hidden: Boolean(options.hidden),
            getElementById: () => options.listStatuses ? null : notice,
            querySelectorAll: () => listTargets
        },
        Date: { now: () => now },
        URL,
        window: {
            location: {
                href: "https://merchant.example/Pharma_Flow/orders?action=detail&id=901&payment=pending",
                replace: value => redirects.push(new URL(value)),
                reload: () => reloads++
            },
            setTimeout: callback => timers.push(callback)
        },
        fetch: async (url, config) => {
            requests++;
            const row = listTargets.find(target => target.dataset.paymentStatusUrl === url);
            if (options.listStatuses) assert.ok(row);
            else assert.equal(url, notice.dataset.statusUrl);
            assert.equal(config.credentials, "same-origin");
            assert.equal(config.cache, "no-store");
            if (options.networkError) throw new Error("offline");
            return {
                ok: !options.httpError,
                status: options.httpError || 200,
                redirected: Boolean(options.redirected),
                json: async () => ({ paymentStatus: row ? row.status : options.paymentStatus || "CHO_THANH_TOAN" })
            };
        }
    };
    vm.runInNewContext(source, context);
    if (options.expired) now = 20 * 60 * 1000 + 1;
    if (timers.length) await timers.shift()();
    return { timers, redirects, notice, requests, reloads };
}

(async () => {
    let result = await scenario();
    assert.equal(result.redirects.length, 0);
    assert.equal(result.timers.length, 1);
    result = await scenario({ paymentStatus: "DA_THANH_TOAN" });
    assert.equal(result.redirects[0].searchParams.get("ok"), "paid");
    assert.equal(result.redirects[0].searchParams.get("id"), "901");
    assert.equal(result.redirects[0].searchParams.has("payment"), false);
    assert.equal(result.timers.length, 0);
    result = await scenario({ paymentStatus: "THAT_BAI" });
    assert.equal(result.redirects[0].searchParams.get("err"), "payment_failed");
    result = await scenario({ networkError: true });
    assert.equal(result.redirects.length, 0);
    assert.equal(result.timers.length, 1);
    result = await scenario({ redirected: true });
    assert.equal(result.redirects.length, 0);
    assert.equal(result.timers.length, 0);
    assert.match(result.notice.textContent, /đăng nhập/);
    result = await scenario({ httpError: 404 });
    assert.equal(result.timers.length, 0);
    assert.match(result.notice.textContent, /Không tìm thấy/);
    result = await scenario({ hidden: true });
    assert.equal(result.requests, 0);
    assert.equal(result.timers.length, 1);
    result = await scenario({ expired: true });
    assert.equal(result.requests, 0);
    assert.equal(result.timers.length, 0);
    result = await scenario({ listStatuses: [] });
    assert.equal(result.requests, 0);
    assert.equal(result.timers.length, 0);
    result = await scenario({ listStatuses: ["CHO_THANH_TOAN", "CHO_THANH_TOAN"] });
    assert.equal(result.requests, 2);
    assert.equal(result.reloads, 0);
    assert.equal(result.timers.length, 1);
    result = await scenario({ listStatuses: ["CHO_THANH_TOAN", "DA_THANH_TOAN"] });
    assert.equal(result.requests, 2);
    assert.equal(result.reloads, 1);
    assert.equal(result.redirects.length, 0);
    assert.equal(result.timers.length, 0);
    result = await scenario({ listStatuses: ["CHO_THANH_TOAN"], networkError: true });
    assert.equal(result.reloads, 0);
    assert.equal(result.timers.length, 1);
    result = await scenario({ listStatuses: ["CHO_THANH_TOAN"], httpError: 401 });
    assert.equal(result.timers.length, 0);
    result = await scenario({ listStatuses: ["CHO_THANH_TOAN"], expired: true });
    assert.equal(result.requests, 0);
    assert.equal(result.timers.length, 0);
    console.log("PASS 14 payment status browser scenarios");
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
