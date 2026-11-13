---
{"id":"checksums-and-profile-pipelines","language":"zh-CN","title":"校验位与生成式主页：两个小项目里的契约思维","summary":"从 CardCalulatorSimulator 的 Luhn 约束到 GitHub Profile 的 SVG 生成，观察输入、输出和来源如何保持一致。","category":"工程札记"}
---

## 校验和只回答一个窄问题

CardCalulatorSimulator 接受固定数字、同字母同值变量与独立通配符，再筛选通过 Luhn 的组合。另一个模式从起点寻找后续候选，并用相同评分器评价尾号模式。

通过 Luhn 只说明数字满足校验关系，不说明它已发行、有账户或可用于支付。把校验、约束求解与偏好评分拆开，界面才不会把一个算法结果包装成现实世界的身份事实。

## 唯一校验位减少不必要枚举

前缀确定后，Luhn 的末位校验数字是唯一的。求解器因此可以计算末位，避免把它当作又一个十选一变量。相同字母的约束又不同于通配符，替换时必须维持共享变量一致。

重计算放在后台 isolate，结果再交回 UI。取消、输入变化与迟到结果之间仍需要身份关联，否则上一轮候选可能覆盖用户已经输入的新模式。算法正确和交互正确都要验证。

## 主页的输出应该可重建

blueokanna 同名仓库是 GitHub Profile。README 使用生成的 SVG，scripts 保存模板、布局和渲染入口，Actions 定期更新实际 GitHub 数据。修改模板再生成，比手动修改最终 SVG 更容易保持一致。

连续背景跨卡片显示时，尺寸与偏移是同一份布局契约。一个卡片高度变化后，后续偏移也必须跟随；否则看起来是图片接缝问题，实际是源参数失去同步。

## 统计来源需要被保留

认证和未认证 GitHub 请求使用的数据通道可能不同，还受到限流和更新时间影响。生成的卡片是某次构建的快照，不能称为实时数据。构建失败时保留旧卡片，也应保留它属于旧快照这一事实。

脚本使用临时文件和 rename，避免中断留下半份输出。这个模式适用于很多内容生成流程：先完整生成并检查，再替换读者正在使用的版本。

## 加密输入与公开输出并不矛盾

源图片可以加密保存在仓库，并在构建时解密组合进卡片；最终公开 SVG 仍然是公开内容。加密原始资产不代表用户看不到发布后的图像，也不应被宣传为防复制机制。

真正需要保密的是构建令牌与解密密钥。它们留在构建环境，不进入模板输出、日志或进程参数。公开页面只应该包含用于展示的结果。

## 小项目同样值得清楚表达

这两个项目没有共同产品功能，但都需要避免把输出解释得过宽：候选号码不代表账户，构建统计不代表实时遥测，模板生成成功也不证明每个链接可用。输入、处理和输出的定义越清楚，小工具越容易被放心复用。

## 核对来源

本文于 2026 年 11 月 13 日按以下固定提交核对。仓库后续行为以对应版本源码为准。

- [CardCalulatorSimulator · d94b5aa](https://github.com/blueokanna/CardCalulatorSimulator/blob/d94b5aa7267680cd3abfb5bdc50bbc7b0a30d7e7/README.md)
- [blueokanna · 73e50c9](https://github.com/blueokanna/blueokanna/blob/73e50c985ab57385abfc6d68f1e6c3a40ccf1ce5/README.md)
- [blueokanna / scripts/README.md](https://github.com/blueokanna/blueokanna/blob/73e50c985ab57385abfc6d68f1e6c3a40ccf1ce5/scripts/README.md)

