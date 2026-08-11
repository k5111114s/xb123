# MoonHAR HTTP Archive 解析与性能分析库 项目申报书

## 基本信息

项目名称：MoonHAR HTTP Archive 解析与性能分析库  
参赛者：许博  
联系方式：2230679121@qq.com  
GitHub 仓库链接：https://github.com/k5111114s/xb123  
项目方向：MoonBit Web 性能分析基础库 / HTTP Archive 工具  
是否为移植项目：否

## 项目简介

xb123 计划实现一个 MoonBit 原生的 HAR（HTTP Archive）解析、校验与分析库，用于读取浏览器 DevTools、自动化测试、代理抓包工具导出的 `.har` 文件，并输出请求统计、耗时分解、资源类型汇总、错误诊断和可复现的文本报告。项目面向前端性能分析、接口排查、CI 性能回归检查、网络请求审计和 MoonBit 工具链示例工程，提供可复用的数据模型、解析器、校验器、分析器和命令行示例。

## 核心功能范围

提供 HAR 1.2 风格的数据模型，覆盖 log、page、entry、request、response、cache、timings、headers、cookies、queryString 和 postData 等结构；  
支持从 JSON 解析 HAR 文档，并保留未知字段，便于兼容不同浏览器和代理工具导出的扩展字段；  
提供结构化校验能力，检查必填字段、时间格式、状态码、耗时字段、请求响应大小、MIME 类型和 URL 格式；  
提供性能分析模块，统计总请求数、失败请求数、域名分布、资源类型分布、状态码分布、慢请求列表和页面加载阶段耗时；  
提供瀑布流数据归一化能力，输出适合前端渲染或 CI 报告使用的紧凑 JSON；  
提供 CLI 示例，可对 `.har` 文件执行 summary、validate、slow、domains 和 export-report 等命令；  
提供不少于 80 个真实有效测试，覆盖正常 HAR、字段缺失、异常 timing、跨域资源、重定向、缓存命中、POST body 和大型请求集合；  
提供 README、示例 HAR、测试说明、CI 配置和 mooncakes.io 发布准备文件。

## 移植或参考说明

本项目为原创 MoonBit 项目，不直接移植其他开源项目代码。  
项目会参考公开的 HAR 1.2 数据格式说明和浏览器导出的 HAR 文件结构进行兼容性设计，但核心数据模型、解析逻辑、校验规则、分析算法、测试用例和文档均使用 MoonBit 重新实现。  
本项目许可证采用 Apache License 2.0。
