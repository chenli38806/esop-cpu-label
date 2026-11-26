# esop-cpu-label

把 CPU 标签原图做成产线 ESOP 用的**放大核对图**：标签旁放大性能等级数字、红框圈出小字版本（ENT / EVO / Ess / An EVO / Cop / AI / GRA / GOLD / 丝印）、绿色箭头指位，底部固定加联想 PN + 供应商 PN。

解决的问题：现场 ESOP 上的 CPU 标签字太小，员工核对等级和 vPRO 版本很吃力，错装、错料由此产生。

## 一键安装（另一台 Windows 电脑）

```powershell
irm https://raw.githubusercontent.com/chenli38806/esop-cpu-label/main/install-online.ps1 | iex
```

脚本自动完成：检查 Python → 缺 Pillow 就装 → 下载 `esop-cpu-label.zip` → 解压安装到豆包用户技能目录 → 检查中文字体 → 脚本语法自检。

前置条件只有一个：**Python 3.9+**，安装时勾选 "Add python.exe to PATH"。

装完重启豆包客户端，直接说：

> 把这个 CPU 标签做成 ESOP 核对图，联想 PN xxx，供应商 PN xxx

## 它做什么

| 元素 | 做法 |
| --- | --- |
| 性能等级数字 | 微软雅黑加粗，标准红 `#FF0000`，字号 ≈ 标签宽度 30% |
| 小字版本 | 红色，字号 ≈ 标签宽度 17%，外套红色矩形框 |
| 指示箭头 | 标准绿 `#00B050`，单向实线粗箭头，从标注指向标签上对应文字 |
| 标签内红框 | 红色实线，**精确圈住那行真实印刷的字** |
| 底部双 PN | 联想 PN 大号红字 + 供应商 PN 小号红字，固定加在底部 |

标签本体只做等比缩放 + 轻锐化，**不重绘、不裁剪**——Intel / AMD 的 logo 必须保真。

## 仓库里有什么

```
install-online.ps1      远程一键安装脚本（自包含）
esop-cpu-label.zip      技能本体（SKILL.md + 5 个脚本 + 规则库 + 样例）
README.md               本文件
```

技能本体解开是：

```
esop-cpu-label/
├─ SKILL.md                  技能说明书
├─ scripts/
│  ├─ esop_build.py          渲染器
│  ├─ validate.py            出图前自动校验
│  ├─ preview_anchor.py      锚点自检（框内内容放大条）
│  ├─ measure_grid.py        网格尺
│  └─ make_overview.py       批量拼总览
├─ references/label-rules.md 规则表 + 17 张已验证锚点坐标
└─ assets/                   样例图、样例配置、17 条真实案例配置
```

## 手动安装（下载 zip 自己解压）

1. 下载本仓库的 `esop-cpu-label.zip` 并解压。
2. 把 `esop-cpu-label` 文件夹复制到：

```
C:\Users\<用户名>\AppData\Local\Doubao\User Data\Default\.doubao\agent_mode\workspace\.user_skills\
```

3. `python -m pip install pillow`
4. 重启豆包客户端。

## 为什么做锚点自检

最容易翻车的不是排版，是**红框框错位置**：AMD 标签写着 "7000 SERIES"，但 `7000` 只印在底部条上，AMD RYZEN 大字区根本没有这个数字。凭型号名推断，框一定落错。

所以流程里加了两道关：

1. `validate.py` 自动判定：框越界、**框内几乎没笔划（框到空白）**、缺 PN、框过大过小、框重叠——有 ERROR 直接卡住不出图。
2. `preview_anchor.py` 肉眼复核：原图上叠加所有框，底部多一条**框内实际内容放大条**，框里是不是那几个字一眼可见。

## 使用约定

- 联想 PN / 供应商 PN **绝不编造**，必须用户提供或从原始文件逐字抄。
- 一代一页、一批一版式，命名 `序号_品牌_型号_标注.png`。
- 同屏两个标签间距 5 mm 以上。

## License

MIT
