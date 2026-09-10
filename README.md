# A2UI 3B 实习项目交接（2026-09-10）

> 私有内部交接仓库。未经代码、数据、模型和素材权利复核，请勿改为公开仓库或转发 Release 链接。

本仓库对应四份交付物。文件本体位于 [handoff-20260910 Release](/releases/tag/handoff-20260910)，Git 历史只保存说明、清单、校验值和重组脚本，避免把大型二进制写入普通 Git。

| 编号 | 原始文件 | 大小 | SHA256 | Release 形态 |
| --- | --- | ---: | --- | --- |
| 01 | `01-通用模板设计规范.zip` | 118,579 B | `503497bec91da90bf005ab43758d812cc8fc3cf403384270436f58777a5d3d56` | 原 ZIP |
| 02 | `02-种子与扩展数据.zip` | 10,320,132 B | `24f4fc5bd0da4ea9d43e50e9b11f572dd4b5e418627168e7674406f82fa52406` | 原 ZIP |
| 03 | `03-完整工程项目.zip` | 14,199,189,877 B | `b721a3cf0ffa80060e484c792fd6052724b56eac381e75446d85f9a1f7993a95` | 8 个无损分卷 |
| 04 | `04-专属模板渲染器源码与实验说明.zip` | 68,715,998 B | `abe8f416beb2b64d7ee9f6afd42179733f7726f3a72045157a66aa2011a4f785` | 原 ZIP |

## 下载

浏览器可在 Release 页面逐项下载。安装 GitHub CLI 后，也可在仓库目录执行：

```powershell
gh release download handoff-20260910 --dir downloads
```

Release 共 11 个附件：01、02、04 各一个，03 为 `part01` 至 `part08`。精确名称、大小与 SHA256 以 [`release-manifest.json`](release-manifest.json) 为准。

## 校验附件并重组 03

Windows PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Test-ReleaseAssets.ps1 -AssetDirectory downloads
powershell -ExecutionPolicy Bypass -File scripts/Restore-ProjectArchive.ps1 -AssetDirectory downloads -OutputPath downloads\03-完整工程项目.zip
```

跨平台 Python：

```bash
python scripts/reassemble.py --asset-dir downloads --output downloads/03-完整工程项目.zip
```

脚本会先核对每个分卷的大小和 SHA256，再按 `part01`—`part08` 拼接，最后验证重组文件的字节数及 SHA256。输出路径已存在时脚本会拒绝覆盖。

## 内容说明

- 01：十份通用模板设计 JSON、共享样式/自检规范和说明；
- 02：种子数据、扩展 5000 条数据及相关审计；
- 03：完整工程、渲染器、数据、文档和模型产物；
- 04：专属模板渲染器实际 TSX/TypeScript/CSS/Canvas/素材源码及实验说明。

## 校验资料

`manifests/` 保存四份包的逐文件清单、打包预检和最终交接审计。打包预检未发现内嵌高置信度密钥或未解析链接；这不等同于法律、开源许可或数据分级批准，因此仓库保持私有。

## 已知边界

原工程保留既有测试和类型诊断，详情在 03、04 的交接说明中；本仓库发布动作不修改工程实现。四份 ZIP 是交付物，GitHub Release 只是传输载体。
