---
{"id":"embedded-wallet-boundaries","language":"zh-CN","title":"从 ESP32 对话实验到设备钱包：硬件工程不能跳过验收","summary":"分别阅读 ESP32-ChatGLM、HexWallet 与 Flipper 钱包工程，明确原型、设备集成和托管安全之间的距离。","category":"嵌入式"}
---

## 同一块 MCU 可以承担不同职责

ESP32-ChatGLM 把板子作为云端模型的输入输出终端：联网请求、网页交互、麦克风采集与串口语音输出。大模型在服务端，板端的关键约束是内存、时钟、凭据和外设。

设备钱包则相反，关键秘密和审阅决策应该留在设备。HexWallet 的架构把交易解析、显示与签名放到 MCU，主机提交待处理数据；是否完成这条可信链路，比板子能不能显示一个钱包图标更重要。

## 旧的联网示例需要重新核对

ESP32-ChatGLM 文档记录了具体 Arduino 库、JWT 格式和语音模块编码。它们足以解释历史实现，但不能自动作为今天所有 SDK 的安装说明。认证方式、TLS 校验和依赖 API 都需要在实际构建前再次确认。

音频采集还要核对采样频率、缓冲长度和中断工作量。串口 TTS 的 GB2312 转换与模型返回 UTF-8 之间有真实边界，乱码或丢字不能简单归因为模型质量。

## HexWallet 的当前限制必须放在前面

固定版本 README 明确说明：安全元件托管集成和硬件验收尚未完成。虽然 SCP03、APDU 与 provisioning 路径存在，钱包仍在 MCU RAM 派生和签名；设备默认 custody gate 会拒绝创建、导入与使用钱包。

这意味着当前设备构建不能被介绍为已完成的真实资产钱包。主机回归、板级编译和策略检查是不同证据，不能借用其成功来补齐尚未记录的刷机签名、节点接受与独立审计。

## 交易确认要绑定用户实际看到的内容

审阅结构需要限制大小，拒绝不支持的交易，并把确认绑定到当前显示帧。确认还应有时效且只能消费一次，否则主机可能把一次批准挪给另一份载荷。

安全元件也不能只通过一个“已连接”标记宣称托管完成。通道认证、用户认证、不可导出密钥与实际句柄使用都需要成立，真实签名路径必须经过这些条件。

## Flipper 工程应从源码读起

flipper_zero_wallet 的 README 仍保留模板说明，但 src/lib.rs 已公开钱包、派生、哈希、存储和设备 UI 模块。准确的状态是“有业务实现、说明与验收不足”，不能随意归为纯空壳或成熟产品。

研究时可以先读模块关系，再使用公开测试向量检查算法；不要把真实助记词当调试输入。一个演示能跑，与可以安全保管长期秘密，中间还有很长的设备集成与审查路径。

## 有价值的进展是什么

对这类项目，清晰记录哪个板型、哪份固件、哪些外设与哪条流程被验证，比增加宣传功能数更有用。失败门控、未配置引脚和未验收状态都应该如实显示；拒绝执行本身可以是当前正确行为。

## 核对来源

本文于 2026 年 11 月 13 日按以下固定提交核对。仓库后续行为以对应版本源码为准。

- [ESP32-ChatGLM · 3a2b6c1](https://github.com/blueokanna/ESP32-ChatGLM/blob/3a2b6c14fc7c70211dba445d22f2f05fa0bfb8b0/README.md)
- [HexWallet · edbb9a9](https://github.com/blueokanna/HexWallet/blob/edbb9a9eb9a0b367616783b6ed5a46884085782f/README.md)
- [flipper_zero_wallet · 8e1fd82](https://github.com/blueokanna/flipper_zero_wallet/blob/8e1fd82458c3ead7db4a8a03f934dcd530444c0b/README.md)
- [flipper_zero_wallet / src/lib.rs](https://github.com/blueokanna/flipper_zero_wallet/blob/8e1fd82458c3ead7db4a8a03f934dcd530444c0b/src/lib.rs)

