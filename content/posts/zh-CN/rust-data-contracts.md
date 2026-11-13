---
{"id":"rust-data-contracts","language":"zh-CN","title":"NextJson、RustBinary、Tzcraft 与 RustMacro：把数据契约串起来","summary":"类型、编码、时间和编译诊断如何分工，以及跨版本兼容为什么需要独立设计。","category":"Rust 工具链"}
---

## 类型只是契约的起点

NextJson 把类型元数据与编解码接口放在一起。一个字段的名称、默认值、可选性和数值范围，不只是 Rust 类型问题，也是另一端如何理解字节的问题。导出 Schema 或比较版本差异，能让这些变化在发布前被看见。

直接解码进入字段和借用输入字符串可以减少中间表示，但借用值依赖原始缓冲生命周期。接口设计应让调用者知道什么时候需要拥有数据，而不是把省下来的复制变成难以定位的悬空资源设计。

## 同一类型可以有不同 wire shape

RustBinary 在 NextJson 契约上提供二进制表示。动态流带类型标签，紧凑 profile 依赖双方共享 schema，archive 又是独立版本的存储格式。三种形式解决不同问题，不应靠一个隐式开关猜测输入是什么。

例如动态 null 表示不能区分所有嵌套 Option，而 compact 使用显式标签。看似相同的业务对象，一旦换编码就可能改变可表达状态。选型时要先验证业务是否使用这些状态，再比较输出长度。

## 版本兼容是双方共同承担的工作

增加字段、调整默认值、改枚举表示或改变整数范围，都可能让旧端发生不同解释。格式支持很多，不会自动修复这些语义差异。建议保留真实历史 fixture，并对旧读新、新读旧以及未知字段分别给出预期。

解析限制也应精确描述。输入深度和长度上限可以阻止部分资源耗尽，却不是整个进程的内存沙箱；解压、应用对象和业务缓存仍可能另行分配。

## 时间类型需要分清瞬间和日历

Tzcraft 以 i128 纳秒计数表达瞬间，用 Duration 表达跨度；日期、星期和固定偏移投影到同一时间轴。固定 +08:00 可以表达当前中国标准时间，但不包含历史时区变更和全球夏令时规则。

“一个月后”与“30 天后”也不能混用。月底、闰日、负时间和溢出应通过类型和检查操作明确处理。文本 RFC 3339 和二进制计数可以共用类型语义，但仍要记录单位与偏移。

## 好诊断让错误留在输入处

RustMacro 直接使用 proc_macro 组织 span 与 compile_error!，让错误指向具体 token；需要时收集多个诊断，或追加受控的 dummy 实现减少连锁报错。

它改善的是宏的反馈方式，而不是替调用者证明宏展开正确。成功样例与编译失败样例都应作为契约：前者核对生成行为，后者核对拒绝条件、位置和消息。

## 这组库怎样协作

可以先用 NextJson 描述业务结构，再按传输场景选择文本或 RustBinary 布局；时间字段由 Tzcraft 提供明确语义，派生阶段的问题由宏诊断定位。每一层都应保留自己的错误边界。

构建时固定 feature 与锁文件，测试时使用业务数据和历史样本。零外部依赖、no_std 或压缩格式都是结构事实，不应被延伸成未经测量的速度、内存或安全保证。

## 核对来源

本文于 2026 年 11 月 13 日按以下固定提交核对。仓库后续行为以对应版本源码为准。

- [NextJson · ce09ccb](https://github.com/blueokanna/NextJson/blob/ce09ccb0d4919bfe64ed5cd5d66481f5c3268837/README.md)
- [RustBinary · 4299aeb](https://github.com/blueokanna/RustBinary/blob/4299aeb4def2a4d2c13536ad75878baec20a1006/README.md)
- [Tzcraft · 8705262](https://github.com/blueokanna/Tzcraft/blob/87052622f817218f7bf7f119af0303e7cdd0988a/README.md)
- [RustMacro · a8260f9](https://github.com/blueokanna/RustMacro/blob/a8260f9121cb9d34b663d0d1d739614dbe2f9932/README.md)

