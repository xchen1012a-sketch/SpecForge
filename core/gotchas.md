# 通用踩坑清单（模板）

> **每个项目都该维护自己的 gotchas**。
> 把"踩过的坑 + 现象 + 原因 + 解决方案"记录在这里，下次 AI 协作时直接读到。
> 删除不适用条目，追加项目特定条目。

---

## 一、构建 / 依赖

### 1.1 BOM / 依赖管理包首次构建
- **现象**：清仓或新机器首次构建失败，提示找不到 BOM 依赖
- **原因**：BOM（Bill of Materials）是 import 模式，reactor build 的 `-am` 不会自动带它
- **解决**：先手动 install BOM，再 reactor build
  ```bash
  mvn install:install-file -Dfile=xxx-bom/pom.xml -DgroupId=... -DartifactId=xxx-bom -Dversion=... -Dpackaging=pom
  ```

### 1.2 锁文件不一致
- **现象**：本地能跑、CI 跑不起来（或反之）
- **原因**：`package-lock.json` / `pnpm-lock.yaml` / `Cargo.lock` / `go.sum` 与代码不同步
- **解决**：每次改依赖立即 commit 锁文件；CI 校验锁文件一致性

### 1.3 多版本依赖冲突
- **现象**：`ClassNotFoundException` / `MethodNotFoundError` / 运行时报版本不兼容
- **原因**：传递依赖引入了多个版本
- **解决**：用 dependency tree 排查（`mvn dependency:tree` / `npm ls`），显式锁定版本

---

## 二、缓存

### 2.1 改包名 / 类名后缓存反序列化失败
- **现象**：启动后调用接口报 Jackson / JSON 反序列化失败，FQN 类名找不到
- **原因**：Redis 缓存里存的是旧 Fully Qualified Name，新代码找不到旧类
- **解决**：改包名 / 类名后立即 `redis-cli FLUSHDB`（或选择性 DEL）

### 2.2 CDN / 浏览器缓存
- **现象**：前端发布后部分用户看到旧版本
- **原因**：CDN / 浏览器缓存 HTML / JS
- **解决**：HTML 不缓存（`Cache-Control: no-cache`），JS / CSS 用内容 hash 文件名

### 2.3 缓存击穿 / 雪崩
- **现象**：缓存同时失效，DB 瞬间被打爆
- **解决**：过期时间加随机抖动；热 key 互斥锁；空值缓存防穿透

---

## 三、JSON / 序列化

### 3.1 snake_case / camelCase 不一致
- **现象**：前端拿不到字段（key 不对）
- **原因**：后端默认 camelCase，前端期望 snake_case（或反之）
- **解决**：用 `@JsonProperty("xxx")` / Jackson 命名策略 / 框架配置明确指定

### 3.2 数字精度丢失
- **现象**：金额计算差 1 分钱
- **原因**：用 float / double 存金额
- **解决**：用 decimal / integer（分为单位）；后端 BigDecimal，前端字符串

### 3.3 大整数 ID 精度丢失
- **现象**：JavaScript 拿到雪花 ID 后精度变了（如 `123456789012345678` → `123456789012345680`）
- **原因**：JS Number 只能安全表示到 2^53
- **解决**：后端把 Long ID 序列化为字符串（`ToStringSerializer`）

### 3.4 时间格式 / 时区
- **现象**：跨时区时间错乱
- **解决**：统一 ISO 8601 + UTC；前端按用户时区显示；DB 存 UTC

---

## 四、SPI / 反射 / 注解

### 4.1 SPI 文件改名后失效
- **现象**：改包名后某些功能（如验证码、登录方式）失效
- **原因**：`META-INF/services/*` 文件内容是 FQ 类名，改包名后对不上
- **解决**：批量改包名时同步检查 SPI 文件、Spring factories、注解扫描配置

### 4.2 反射找不到类
- **现象**：Class.forName 报 ClassNotFoundException
- **原因**：模块化（JDK 9+）/ 类加载器隔离 / 混淆移除类名
- **解决**：模块声明 opens；避免反射，用接口 + 工厂

---

## 五、大数据量

### 5.1 Excel / CSV 导出 OOM
- **现象**：导出大数据量时内存爆
- **原因**：一次性加载全部行到内存
- **解决**：流式写（EasyExcel / pandas chunk / openpyxl write_only）

### 5.2 一次性查询返回百万行
- **现象**：DB 连接超时 / OOM
- **解决**：分页（必有 LIMIT）；流式 cursor；分批处理

---

## 六、并发 / 锁

### 6.1 双击重复提交
- **现象**：用户点两次"提交"，后台创建两条数据
- **解决**：前端按钮防抖 + 后端幂等键

### 6.2 乐观锁失效
- **现象**：高并发下数据错乱
- **原因**：version 字段没更新 / 没参与 WHERE 条件
- **解决**：`UPDATE ... SET version=version+1 WHERE id=? AND version=?`，affected=0 即重试

### 6.3 死锁
- **现象**：偶发的请求超时
- **原因**：锁顺序不一致（A 先锁 1 后锁 2；B 先锁 2 后锁 1）
- **解决**：统一锁顺序；减小锁粒度；用乐观锁替代悲观锁

---

## 七、多租户 / 数据隔离

### 7.1 漏注入 tenant_id
- **现象**：A 租户能看到 B 租户的数据
- **原因**：某条 SQL / Repository 绕过了租户拦截器
- **解决**：所有 DO 继承 TenantBaseDO；定期审计 SQL 是否带 tenant_id

### 7.2 超管跨租户操作
- **现象**：超管误操作影响所有租户
- **解决**：超管操作强制二次确认 + 审计日志

---

## 八、网络 / 超时

### 8.1 第三方 API 超时拖垮服务
- **现象**：外部 API 慢，自己服务的连接池被耗尽
- **解决**：所有外部调用必须有超时（连接 + 读）+ 熔断 + 降级

### 8.2 重试风暴
- **现象**：外部服务慢，重试把外部打挂
- **解决**：指数退避；最大重试次数；熔断

---

## 九、Git / 协作

### 9.1 .env / 密钥误提交
- **现象**：密钥进 git 历史
- **解决**：`.gitignore` 配齐；用 `git-secrets` / `trufflehog` 扫描；提交后立即轮换密钥

### 9.2 大文件进 git
- **现象**：仓库膨胀
- **解决**：用 LFS；或重新写历史（git filter-repo）

### 9.3 跨平台换行符
- **现象**：Windows 提交的文件在 Linux 显示 `^M`
- **解决**：`.gitattributes` 配 `* text=auto`

---

## 十、文档历史

> 每次新增 gotcha，记录发现日期 + 当事人（可选）：
> - 2026-06-19：初始化模板

---

## 模板条目格式（供你追加）

```markdown
### X.Y 标题
- **现象**：用户看到什么 / 日志报什么
- **原因**：根本原因（不是表象）
- **解决**：具体步骤 / 命令 / 代码
- **预防**：CI 检查 / lint 规则 / 文档提醒
- **发现日期**：YYYY-MM-DD
```
