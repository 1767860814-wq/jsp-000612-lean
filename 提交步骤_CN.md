# JSP-000612：使用这一版提交官方审查

**这版已经改成“外部证明仓库 + 官方目录证据 PR”的路线。不要再照旧包只开 Recipient Issue。**

本包可以用于发起审查，不是“官方验收完成/奖金已确定”的凭证。独立检查器、安全版本、首发优先权、身份和奖金仍由实际审查决定。原始发散猜想的否定是本次提交范围；没有宣称证明全部更强的最优公式。

## 第一步：公开你自己的证明仓库

在 GitHub 新建公开仓库，例如 `jsp-000612-lean`。解压本 ZIP，把内层工程目录的内容上传到仓库根目录。

根目录应直接看到 `JSP000612.lean`、`SubmissionChallenge.lean`、`GateSupport.lean`、`StatementGate.lean`、`lean-toolchain`、`lakefile.lean`、`lake-manifest.json`、`verify_submission.sh`，以及 `tools/`、`tests/`、`submission/`、`evidence/` 等文件夹。包含的 `.gitignore` 也应保留。不要只上传 ZIP，更不要上传几 GB 的 Lean 环境。源码、依赖和测试文件应保持原样。

记录三项真实信息：公开仓库网址、分支名（通常是 `main`）、该次上传的完整 **40 位 Git commit**。40 位 commit 不是源码的 64 位 SHA-256。公开仓库可能显示你的 GitHub 资料；自行检查后再公开，不需要在申请中提供证件、银行卡或钱包地址。

## 第二步：生成英文正文和目录插入段落

不熟悉终端时：复制 `submission/PR_BODY_EN.template.md` 和 `submission/CATALOG_INSERT_EN.template.md` 的正文到文本编辑器，替换所有 `PUBLIC_REPOSITORY_URL`、`PUBLIC_BRANCH`、`PUBLIC_COMMIT_SHA`。不要把未替换的占位符提交。

熟悉终端时，在解压工程目录运行：

```bash
python3 tools/prepare_submission.py \
  --repository https://github.com/你的账号/你的仓库 \
  --branch main \
  --commit 这里填真实40位commit
```

上面是模板，不可原样执行。填写真实值后，结果在 `reproduction/submission/`：

- `PR_BODY_EN.md`：官方 PR 的英文正文。
- `CATALOG_INSERT_EN.md`：插入612题目录的英文证据段落。
- `PR_TITLE.txt`：标题。

工具不会联网发布，也不会冒充已检查公开仓库。生成的文件用于下一步粘贴，不需要提交回证明仓库，因此不会发生“更新正文导致原commit失效”的循环。手动替换时也使用副本，保留公开工程原文件以通过完整性检查。

## 第三步：向官方仓库发起 PR

官方仓库： https://github.com/TheJustinSunPrize/awards

Fork 官方仓库；在自己的 fork 中编辑 `problems/catalog-0601-0700.md`，找到 **JSP-000612**。在该题现有表格之后、**JSP-000613** 标题之前，插入生成的 `CATALOG_INSERT_EN.md` 段落。

**保留现有 `Current status`、`Lean proof`、`Eligible to claim` 等字段，不要自行改成通过。** 不要创建一个重复的612题，不要把 Lean 源码、依赖环境或 ZIP 加进官方仓库。那些材料已经由你自己的公开仓库承载。

发起 Pull Request，标题使用 `PR_TITLE.txt`，正文使用 `PR_BODY_EN.md`。GitHub 显示默认模板的必填栏目时，把相关内容对应填入；不要删除官方要求的检查项。可附自己证明仓库的公开 Release ZIP 链接作为证据补充，但源码链接和固定 commit 仍必填。

提交前检查：在退出登录/无痕浏览器中能打开公开仓库、固定 commit 的 `JSP000612.lean`、`evidence/current/FINAL_AUDIT_REPORT.json` 和英文正文中的其他链接。搜索官方 Issues/PR 中 `JSP-000612`、`000612`、`Erdos744`；同一项目已有申请应补原帖，发现别人相关提交要交叉引用，不要写“确定没人申请”。本包没有完成跨平台优先权认定。

## 已验证与仍待审的边界

主证明：800行、42个显式定理。新一轮检查包含源码编译、127个定理根/8,000项相关依赖重检、六个主命题的完整类型与公理核对、九种错误候选拒绝、16个有限图检查以及提交脚本测试。最终实际结果以 `evidence/current/FINAL_AUDIT_REPORT.json` 和本次交付附带的封包验收记录为准，不把历史日志当成本轮执行。

同一个 Lean 内核重复运行和本项目编写的命题核对程序，不是另一种独立实现。独立外部检查、安全版本、独立签署的语义审查、首发和获奖资格仍待确认。官方规则安排线上提交后进入指定的离线验证阶段，因此可以如实提交待验证材料；不要把 pending 自行改成 verified。

本轮复现包括本地 Git 固定版本/最终交付文件的检查；你的公开仓库还未提供，**不能把本地克隆说成已经验证了未来的公开仓库**。第一步后必须完成公开链接检查。

申请身份保留 `RECIPIENT-JSP-000612-A`，直到实际取得相应确认。提交的是 AI 辅助形式化贡献，数学历史解答归属已如实注明，不声称我们首次解决了数学问题。

官方流程依据（2026-09-17核对）：
https://www.hejustinsun.com/prize/rules
https://github.com/TheJustinSunPrize/awards/blob/main/CONTRIBUTING.md
https://github.com/TheJustinSunPrize/awards/blob/main/docs/records.md

**保存最终 PR 地址和公开证明 commit。发起审查，不等于通过审查或奖金已确认。**

## 本轮新增：公开版本与已验收材料必须逐文件一致

推荐保留本包为核对基准，在**未改动的本包工程目录**执行下列命令，`--proof-checkout` 指向你将要公开的仓库本地副本。三个 PUBLIC 字段和路径必须换成真实值。

```bash
python3 tools/prepare_submission.py \
  --repository PUBLIC_REPOSITORY_URL \
  --branch PUBLIC_BRANCH \
  --commit PUBLIC_COMMIT_SHA \
  --proof-checkout /absolute/path/to/your/proof-repository
```

本轮新增的检查不仅核对主证明，还读取该 commit 的 Git 对象：核对分支包含该 commit；逐文件比对原交付清单与清单自身；拒绝漏传、额外文件、被换掉的检查器或文档、符号链接、子模块及不同的候选清单。它忽略未提交的工作区变动，以指定 commit 为准，不把后来分支 HEAD 的内容误认为已经验收。

分支检查是本地分支或 origin 的本地跟踪记录，不会联网验证 GitHub，也不会发帖。公开后仍需从无登录视角检查真实链接。即使该检查通过，也不代表首发、独立内核验收或奖金确认。

原始 Lean 源码仍为800行、42个定理，SHA-256未变。新增的是发布防错工具，不是新的数学结果。请使用新版 ZIP；历史日志仍标为历史，不得将其时间戳改成本轮。
