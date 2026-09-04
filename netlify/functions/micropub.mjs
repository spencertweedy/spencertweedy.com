// netlify/functions/micropub.mjs
// Micropub endpoint for a Jekyll site. Verifies bearer tokens against
// tokens.indieauth.com, then commits a markdown post to GitHub, which
// triggers a Netlify rebuild.
//
// Required env vars:
//   GITHUB_TOKEN   fine-grained PAT, contents:write on the site repo
//   GITHUB_REPO    e.g. "spencertweedy/spencertweedy.com"
//   GITHUB_BRANCH  e.g. "main"
//   ME_URL         your canonical identity, e.g. "https://spencertweedy.com/"
//   POSTS_DIR      optional, defaults to "_posts"
//
// Written primarily by Claude

const TOKEN_ENDPOINT = "https://tokens.indieauth.com/token";

exports.handler = async (event) => {
  const cors = {
	"Access-Control-Allow-Origin": "*",
	"Access-Control-Allow-Headers": "Authorization, Content-Type",
	"Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  };

  if (event.httpMethod === "OPTIONS") return { statusCode: 204, headers: cors };

  // Micropub config query — clients GET ?q=config before posting.
  if (event.httpMethod === "GET") {
	const q = event.queryStringParameters || {};
	if (q.q === "config" || q.q === "syndicate-to") {
	  return json(200, { "syndicate-to": [] }, cors);
	}
	return json(200, {}, cors);
  }

  if (event.httpMethod !== "POST") {
	return json(405, { error: "method_not_allowed" }, cors);
  }

  // 1. Verify the token.
  const auth = event.headers.authorization || event.headers.Authorization;
  let token = auth && auth.replace(/^Bearer\s+/i, "");
  const parsed = parseBody(event);
  if (!token && parsed.access_token) token = parsed.access_token;
  if (!token) return json(401, { error: "unauthorized" }, cors);

  let tokenInfo;
  try {
	const res = await fetch(TOKEN_ENDPOINT, {
	  headers: { Authorization: `Bearer ${token}`, Accept: "application/json" },
	});
	if (!res.ok) return json(403, { error: "forbidden" }, cors);
	tokenInfo = await res.json();
  } catch {
	return json(500, { error: "token_verification_failed" }, cors);
  }

  const me = (tokenInfo.me || "").replace(/\/?$/, "/");
  const expected = process.env.ME_URL.replace(/\/?$/, "/");
  if (me !== expected) return json(403, { error: "forbidden", me }, cors);

  const scopes = (tokenInfo.scope || "").split(/\s+/);
  if (!scopes.includes("create") && !scopes.includes("post")) {
	return json(403, { error: "insufficient_scope" }, cors);
  }

  // 2. Build the post.
  const props = parsed.properties || {};
  const title = pick(props.name);
  const content = pick(props.content) || parsed.content || "";
  const category = props.category || parsed.category || [];
  const published = pick(props.published) || new Date().toISOString();

  const date = new Date(published);
  const isArticle = Boolean(title);
  const slug = (title || content || "note")
	.toString()
	.toLowerCase()
	.replace(/[^\w\s-]/g, "")
	.trim()
	.replace(/\s+/g, "-")
	.slice(0, 60) || "note";

  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  const dd = String(date.getDate()).padStart(2, "0");
  const filename = `${yyyy}-${mm}-${dd}-${slug}.md`;
  const dir = process.env.POSTS_DIR || "_posts";
  const path = `${dir}/${filename}`;

  const front = {
	date: date.toISOString(),
  };
  if (title) front.title = title;
  if (category.length) front.categories = category;

  const fileContent =
	"---\n" +
	Object.entries(front)
	  .map(([k, v]) =>
		Array.isArray(v) ? `${k}: [${v.join(", ")}]` : `${k}: ${yaml(v)}`
	  )
	  .join("\n") +
	"\n---\n\n" +
	contentToText(content) +
	"\n";

  // 3. Commit to GitHub.
  const repo = process.env.GITHUB_REPO;
  const branch = process.env.GITHUB_BRANCH || "main";
  const apiUrl = `https://api.github.com/repos/${repo}/contents/${encodeURIComponent(
	path
  ).replace(/%2F/g, "/")}`;

  try {
	const res = await fetch(apiUrl, {
	  method: "PUT",
	  headers: {
		Authorization: `token ${process.env.GITHUB_TOKEN}`,
		Accept: "application/vnd.github+json",
		"User-Agent": "micropub-netlify",
	  },
	  body: JSON.stringify({
		message: `micropub: ${title || slug}`,
		content: Buffer.from(fileContent, "utf8").toString("base64"),
		branch,
	  }),
	});
	if (!res.ok) {
	  const detail = await res.text();
	  return json(500, { error: "commit_failed", detail }, cors);
	}
  } catch (e) {
	return json(500, { error: "commit_failed", detail: String(e) }, cors);
  }

  // 4. Return 201 with the post URL.
  const postUrl = `${expected}${yyyy}/${mm}/${dd}/${slug}.html`;
  return { statusCode: 201, headers: { ...cors, Location: postUrl }, body: "" };
};

// ---- helpers ----

function parseBody(event) {
  const type = (event.headers["content-type"] || "").toLowerCase();
  let raw = event.body || "";
  if (event.isBase64Encoded) raw = Buffer.from(raw, "base64").toString("utf8");

  if (type.includes("application/json")) {
	try {
	  const obj = JSON.parse(raw);
	  // JSON Micropub uses { type: ["h-entry"], properties: {...} }
	  return obj;
	} catch {
	  return {};
	}
  }

  // form-encoded: content=...&name=...&category[]=...
  const params = new URLSearchParams(raw);
  const out = { properties: {} };
  for (const [key, value] of params) {
	const k = key.replace(/\[\]$/, "");
	if (["h", "access_token"].includes(k)) {
	  out[k] = value;
	  continue;
	}
	(out.properties[k] ||= []).push(value);
  }
  return out;
}

function pick(v) {
  if (Array.isArray(v)) return v[0];
  return v;
}

function contentToText(content) {
  // JSON Micropub content can be { html: "..." } or plain string.
  if (Array.isArray(content)) content = content[0];
  if (content && typeof content === "object" && content.html)
	return content.html;
  return String(content || "");
}

function yaml(v) {
  const s = String(v);
  return /[:#{}\[\]&*!|>'"%@`]/.test(s) ? `"${s.replace(/"/g, '\\"')}"` : s;
}

function json(statusCode, obj, headers) {
  return {
	statusCode,
	headers: { ...headers, "Content-Type": "application/json" },
	body: JSON.stringify(obj),
  };
}
