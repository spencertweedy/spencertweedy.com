// Co-written with Claude
//
// Content negotiation for Markdown-web browsers like BonBon, which send
// `Accept: text/markdown`. Those requests get the .md mirror of the page
// (written by _plugins/markdown_mirror.rb); everyone else gets HTML as usual.

export default async (request, context) => {
  const accept = request.headers.get("accept") || "";
  if (!accept.includes("text/markdown")) return context.next();

  const url = new URL(request.url);
  let path = url.pathname;
  if (path.endsWith(".md")) return context.next();
  if (path.endsWith("/")) path += "index.md";
  else if (path.endsWith(".html")) path = path.slice(0, -5) + ".md";
  else if (/\.[a-z0-9]+$/i.test(path)) return context.next(); // images, feeds, etc.
  else path += ".md";

  const md = await fetch(new URL(path, url), { headers: { accept: "text/markdown" } });
  if (!md.ok) return context.next();

  const headers = new Headers(md.headers);
  headers.set("content-type", "text/markdown; charset=utf-8");
  headers.set("content-location", path);
  headers.set("vary", "Accept");
  headers.set("access-control-allow-origin", "*");
  return new Response(md.body, { status: 200, headers });
};

export const config = {
  path: "/*",
  excludedPath: ["/assets/*", "/uploads/*", "/releases/*", "/.well-known/*", "/*.md", "/*.xml", "/.netlify/*"],
};
