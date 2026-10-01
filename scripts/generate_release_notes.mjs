#!/usr/bin/env node
// 从 conventional commits 生成中文 Release 说明。
//
// 用法: node scripts/generate_release_notes.mjs <tag>
//   <tag> 是本次发布的 tag（如 v1.4.0）。上一个 tag 自动从 git tag 列表
//   推断（-v:refname 排序后取它的下一个）；首个 tag 则收录其全部历史。
//
// 输出到 stdout，供 release.yml 的 body_path 使用，也可配合
//   gh release edit <tag> --notes-file <file>
// 手工补发/修订说明。
//
// 分类规则（与 AGENTS.md 提交规范对应）：
//   feat → 🚀 新功能      fix → 🛠 问题修复
//   perf → ⚡ 性能         refactor → ♻️ 优化重构
//   chore/docs/test/ci/style/build → 折叠进「其他」
//   body 含 BREAKING CHANGE → 置顶 ⚠️ 破坏性变更
//   `chore: bump version` 与 merge 提交不入说明。

import { execFileSync } from 'node:child_process';

const tag = process.argv[2];
if (!tag) {
  console.error('usage: generate_release_notes.mjs <tag>');
  process.exit(1);
}

const git = (args) =>
  execFileSync('git', args, {
    encoding: 'utf8',
    maxBuffer: 16 * 1024 * 1024,
  }).trim();

function previousTag(current) {
  const tags = git(['tag', '--sort=-v:refname'])
    .split('\n')
    .map((t) => t.trim())
    .filter(Boolean);
  const i = tags.indexOf(current);
  return i >= 0 ? (tags[i + 1] ?? null) : null;
}

const prev = previousTag(tag);
const range = prev ? `${prev}..${tag}` : tag;

const raw = git([
  'log',
  range,
  '--no-merges',
  '--format=%h%x09%s%x09%b%x1e',
]);

const sections = new Map([
  ['feat', []],
  ['fix', []],
  ['perf', []],
  ['refactor', []],
]);
const breaking = [];
const other = [];

for (const entry of raw.split('\x1e')) {
  const record = entry.trim();
  if (!record) continue;
  const [hash, subject = '', body = ''] = record.split('\t');
  // 版本号提交是发版机械步骤，不进说明
  if (/^chore: bump version/i.test(subject)) continue;

  const match = subject.match(/^(\w+)(?:\(([^)]*)\))?!?:\s+(.+)$/);
  if (!match) {
    other.push(`- ${subject} (${hash})`);
    continue;
  }
  const [, type, scope, text] = match;
  if (/BREAKING CHANGE/i.test(body) || subject.includes('!:')) {
    breaking.push(`- ${scope ? `**${scope}**: ` : ''}${text} (${hash})`);
  }
  const line = `- ${scope ? `**${scope}**: ` : ''}${text} (${hash})`;
  if (sections.has(type)) {
    sections.get(type).push(line);
  } else {
    other.push(line);
  }
}

const out = [];
out.push('## 更新内容');
if (breaking.length > 0) {
  out.push('### ⚠️ 破坏性变更', ...breaking, '');
}
for (const [type, title] of [
  ['feat', '### 🚀 新功能'],
  ['fix', '### 🛠 问题修复'],
  ['perf', '### ⚡ 性能'],
  ['refactor', '### ♻️ 优化重构'],
]) {
  const lines = sections.get(type);
  if (lines.length > 0) out.push(title, ...lines, '');
}
if (other.length > 0) {
  out.push(
    '<details>',
    '<summary>⚙️ 其他（CI / 文档 / 测试）</summary>',
    '',
    ...other,
    '',
    '</details>',
    '',
  );
}
if (out.length === 1) {
  out.push('本版本以内部改进与维护为主。');
}

// 完整变更链接（origin 是 GitHub；SSH 形式转 https）
try {
  const remote = git(['remote', 'get-url', 'origin']);
  const m = remote.match(
    /(?:github\.com[/:])(.+?)\/(.+?)(?:\.git)?$/,
  );
  if (m && prev) {
    out.push(
      '',
      `**完整变更**: https://github.com/${m[1]}/${m[2]}/compare/${prev}...${tag}`,
    );
  }
} catch {
  // 没有 origin 或非 GitHub 远端时省略链接
}

console.log(out.join('\n'));
