#!/usr/bin/env node
// 从 conventional commits 生成中文 Release 说明。
//
// 用法: node scripts/generate_release_notes.mjs <tag>
//   <tag> 是本次发布的 tag（如 v1.4.0）。上一个 tag 取该提交的最近
//   祖先 tag（git describe --tags，排序法兜底）；首个 tag 则收录全部历史。
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

// 上一个 tag = 本次发布提交的最近祖先 tag（语义正确，免疫仓库里的
// 历史遗留 tag：v1.0.x 旧线与废弃的 v2–v4 线都还在 tag 列表里，纯
// 版本排序法会碰巧对但经不起命名碰撞）。describe 必须带 --tags——
// 当前发布线的 tag 是轻量 tag，不带时只搜附注 tag 会被 274 个提交
// 之外的 v1.1.0 坑。describe 不可用时退回版本排序。
function previousTag(current) {
  try {
    return execFileSync(
      'git',
      ['describe', '--tags', '--abbrev=0', '--match', 'v*', `${current}^`],
      { encoding: 'utf8' },
    ).trim();
  } catch {
    const tags = git(['tag', '--sort=-v:refname'])
      .split('\n')
      .map((t) => t.trim())
      .filter(Boolean);
    const i = tags.indexOf(current);
    return i >= 0 ? (tags[i + 1] ?? null) : null;
  }
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

// 用户不可感知的支撑性提交（含 l10n 文案增改）不进功能/修复区，
// 一律折叠进「其他」；TDD 的 (RED)/(GREEN) 阶段标记从展示文本剥掉。
const isSupportCommit = (type, scope) =>
  ['chore', 'docs', 'test', 'ci', 'style', 'build', 'l10n'].includes(type) ||
  scope === 'l10n';

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
  const [, type, scope, rawText] = match;
  if (/BREAKING CHANGE/i.test(body) || subject.includes('!:')) {
    breaking.push(`- ${scope ? `**${scope}**: ` : ''}${rawText} (${hash})`);
  }
  const text = rawText.replace(/\s*\((?:RED|GREEN)\)\s*$/i, '');
  const line = `- ${scope ? `**${scope}**: ` : ''}${text} (${hash})`;
  if (!isSupportCommit(type, scope) && sections.has(type)) {
    sections.get(type).push(line);
  } else {
    other.push(line);
  }
}

const out = [];
out.push('## 更新内容');

// 固定迁移提示：1.2.x 时代 APK 的 versionCode=2，高于 1.3+ 的 1，
// 安装器会拦下并提示"已安装更高版本"。放在折叠区，既醒目又不喧宾夺主。
out.push(
  '<details>',
  '<summary>📱 从 1.2.x 或更早版本升级？请先迁移数据（点开看步骤）</summary>',
  '',
  '新版与 1.2.x 的内部版本号规则不同，直接安装会被系统提示"已安装更高版本"而拦下。完整迁移步骤：',
  '',
  '1. 在旧版中打开 **设置 → 数据 → 导出数据**（文件保存在手机 Downloads 目录；也可在分享面板里另存一份更稳妥）',
  '2. 用文件管理器确认导出文件存在，然后 **卸载旧版 app**',
  '3. 安装本版本 APK',
  '4. 打开新版：**设置 → 数据 → 导入数据**，选择刚才导出的文件',
  '',
  '</details>',
  '',
);
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
const hasCommits =
  breaking.length > 0 ||
  [...sections.values()].some((lines) => lines.length > 0) ||
  other.length > 0;
if (!hasCommits) {
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
