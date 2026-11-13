---
{"id":"cryptography-research-evidence","language":"zh-CN","title":"BlueHash、PQC 与账本实验：如何把研究结论写得可核查","summary":"用具体仓库区分算法实验、测试向量、形式化模型与独立安全证据。","category":"密码研究"}
---

## 先写出证据属于哪一层

密码代码能编译，说明构建条件成立；通过测试向量，说明选定输入输出匹配；有限模型里的证明，说明给定假设与边界内的命题成立。它们都很重要，却不能合并成一个“绝对安全”的标签。

读这些仓库时，本文保留项目确实存在的模块和实验，同时不把函数名、测试数量或 README 自述升级为独立安全结论。不同提交甚至可能属于完全不同的算法版本。

## BlueHash v2 主动收回了什么

BlueHash v2 明确是未经独立审计的实验候选，并指出 v1 曾存在分块不一致、finalize 改变状态和不恰当抗量子表述等问题。修正这些是工程进展，但不能据此断言新结构已经具有成熟哈希的密码分析积累。

可选 ZK 轨道把设计空间和未解决义务记进证书。有限分支模型里的活跃 S-box 计数可以复核；把这一结果外推到所有攻击仍然需要额外论证。production_ready 返回 false 的边界应在介绍中被保留。

## Reveler 的承诺需要验证什么

Reveler 描述 FFT 矩阵运算与 BlueHash 结合的 commit/verify。阅读时要逐项追踪消息、随机量、承诺点和挑战的绑定关系，再核对数值域、舍入与转换是否和数学说明一致。

验证“承诺点的哈希仍匹配”与证明完整承诺方案的隐藏性、绑定性，是不同命题。性能优化应在明确的构造与安全定义之后讨论，不能因为用上 FFT 就自动获得更强安全性。

## PQC 的名字不是归约证明

PQC 的 README 目前只有标题。源码包含 MLWE、密钥演化和几何相关模块，其中 QuantumNoiseSource 的注释明确只是系统熵包装。名字中的量子不表示硬件量子随机源。

类似地，一个方法返回带 security_level 和 quantum_resistant 字段的结构，并不是可审查的数学证明。继续研究需要先写清问题定义、参数、攻击模型、归约步骤和验证方法，才能讨论代码实现是否符合构造。

## WaveLinks 要同时检查密码与分布式状态

WaveLinks 具有签名、哈希、分片账本、VM、证明和网络模块。即使签名校验独立正确，重复交易、网络分区、跨分片中断和重启恢复仍可能改变账本结果。密码性质与分布式一致性需要各自的证据。

客户端显示的金额和仓库设定的代币参数也不代表真实资产价值。介绍系统实验时，应把可观察的交易路径与未经外部确认的安全声明分开。

## 历史工具也要看数据流

BitCalculations 没有 README，默认分支是 master。源码可见地址派生、余额查询和把含 private_key 的对象追加到 JSON 文件的路径。这足以提示研究重点，但不足以承诺编译可用或多链格式正确。

保留这种状态说明，比将所有公开仓库包装成已完成产品更有意义。真实秘密不应成为调试样本；使用公开向量、隔离环境和无价值测试数据，才能让实验本身可复查。

## 核对来源

本文于 2026 年 11 月 13 日按以下固定提交核对。仓库后续行为以对应版本源码为准。

- [BlueHash · 01a33d4](https://github.com/blueokanna/BlueHash/blob/01a33d4747f949792eb908701cb141a1e8d98954/README.md)
- [reveler · d630a40](https://github.com/blueokanna/reveler/blob/d630a4001b6c742dd486a379381aacf2f99c8735/README.md)
- [PQC · 216ee49](https://github.com/blueokanna/PQC/blob/216ee491a69de3116035a62fd2e0ca649aa65a1e/README.md)
- [WaveLinks · e6813be](https://github.com/blueokanna/WaveLinks/blob/e6813bebb748aa9dbb3a6327e1207b0535b0d887/README.md)
- [BitCalculations · 3f46656](https://github.com/blueokanna/BitCalculations/blob/3f46656ef958f033b3963d34380bc959e3ae1f3a/src/main.rs)
- [PQC / src/lib.rs](https://github.com/blueokanna/PQC/blob/216ee491a69de3116035a62fd2e0ca649aa65a1e/src/lib.rs)
- [BitCalculations / src/main.rs](https://github.com/blueokanna/BitCalculations/blob/3f46656ef958f033b3963d34380bc959e3ae1f3a/src/main.rs)

