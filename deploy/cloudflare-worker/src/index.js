/**
 * Edge proxy for Slip pass-engine.
 * Signing stays on OCI (cert-backed). This Worker only terminates TLS at the edge
 * and forwards /v1/* — optional CDN / custom domain in front of Always Free.
 */
export default {
  async fetch(request, env) {
    const origin = (env.PASS_ENGINE_ORIGIN || "").replace(/\/$/, "");
    if (!origin) {
      return Response.json({ error: "PASS_ENGINE_ORIGIN unset" }, { status: 500 });
    }
    const url = new URL(request.url);
    if (!url.pathname.startsWith("/v1/")) {
      return Response.json({
        service: "slip-pass-edge",
        hint: "Proxy /v1/passes, /v1/brands, /v1/health to pass-engine",
      });
    }
    const target = origin + url.pathname + url.search;
    const headers = new Headers(request.headers);
    headers.delete("host");
    const init = {
      method: request.method,
      headers,
      redirect: "follow",
    };
    if (request.method !== "GET" && request.method !== "HEAD") {
      init.body = await request.arrayBuffer();
    }
    return fetch(target, init);
  },
};
