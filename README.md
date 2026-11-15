# C4 Pro Archive

**C4 Pro**（Minecraft 1.20.1 / Forge 47.x 的 CS2 式 C4 模组）开发过程中产生的**环境、日志、素材与产物**存档。
主仓库（模组源码 / 发布 jar）：https://github.com/456123739/C4-Pro

> 这个仓库存在的唯一目的：**把占地方又不常用、但以后可能还要用/要查的东西收起来**，
> 本地只保留源码与最近的构建产物。所有大文件都放在 **Releases** 里（Git 仓库本身很轻）。

---

## 1. 快照清单

| 快照 | 日期 | 内容 |
|------|------|------|
| `env-2026.11` | 2026-11-15 | 1.7.5 收尾时的完整构建/测试环境 + 会话产物 |

### Release `env-2026.11` 资产（大文件）

| 文件 | 大小 | SHA-256 | 说明 |
|------|------|---------|------|
| `server-runtime.tar.zst` | 132 MiB | `03274ad0…b3640fdc` | 可直接跑的 Forge 1.20.1-47.4.16 专用服务器运行时（libraries + config + mods + eula/ops/server.properties），解压即用；**不含 world**（见下） |
| `c4pro-test-world-1.7.5.tar.zst` | 9.1 MiB | 见仓库内 `world/` | 自检跑过的测试存档（含 40×100 平台与远景 C4 区块），用于复现自检场景 |

### 仓库内文件（小而重要）

```
tools/      本会话写过的全部脚本（分段生成、资源校验、离线渲染预览、API 推送等）
logs/       自检 / 实机测试日志（gzip）与 1.7.5 自检报告
preview/    掉落 C4 标记的离线渲染预览图（含 4× 放大）
jars/       1.7.0 / 1.7.1 / 1.7.2 / 1.7.3 / 1.7.4 / 1.7.5 六个版本的 jar
source/     最开始拿到的原始模组源码包 C4-src.zip（sha256 9ea4cdea…）
docs/       玩法说明书（GAMEPLAY.md）、发布说明、changelog
world/      测试存档压缩包
SHA256SUMS.txt / manifest.json   全量校验与机器可读清单
```

---

## 2. 一键恢复

```bash
git clone https://github.com/456123739/C4-Pro-Archive.git
cd C4-Pro-Archive
./restore.sh            # 校验 + 解压 runtime 与 world，并打印工具链下载命令
./restore.sh --check    # 只做校验
```

`restore.sh` 会：

1. 用 `gh release download env-2026.11`（或 `curl` 直链）下载资产到 `downloads/`；
2. 对照 `SHA256SUMS.txt` / `manifest.json` 校验；
3. 解压 `server-runtime.tar.zst` → `server-runtime/`，`c4pro-test-world-*.tar.zst` → `server-runtime/`；
4. 打印重建工具链的命令（JDK / Gradle / Forge 安装器，见下节）。

---

## 3. 工具链（**不**入库，按需下载）

这些是可复现的公共下载，放在这里只记录**确切版本与校验值**，避免仓库里塞几百 MB 的 JDK：

| 组件 | 版本 | 来源 | SHA-256 |
|------|------|------|---------|
| Temurin JDK 17 | 17.0.20.1+1 | `https://mirrors.tuna.tsinghua.edu.cn/Adoptium/17/jdk/x64/linux/OpenJDK17U-jdk_x64_linux_hotspot_17.0.20.1_1.tar.gz` | 未存档（当时未留存 tarball） |
| Gradle | 8.8 | `https://mirrors.cloud.tencent.com/gradle/gradle-8.8-bin.zip` | `a4b41586…7dc612` |
| Forge 安装器 | 1.20.1-47.4.16 | `https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.4.16/forge-1.20.1-47.4.16-installer.jar` | `29e3d453…b6008f` |

> 注：JDK 与 Gradle 目录在本机被其他项目共用，按用户要求**保留未删**；
> 本仓库只存"重建它所需的信息"，不重复托管。

### 从零构建模组

```bash
git clone https://github.com/456123739/C4-Pro.git && cd C4-Pro
JAVA_HOME=/path/to/jdk17 ./gradlew build          # 产物 build/libs/qis4c4-*.jar
# 首次构建约 17 分钟（下载 MC/Forge/映射），之后增量 15~20 秒
```

### 跑自检（真实专用服务器）

```bash
cd server-runtime
java -Dqis4c4.selftest=true -Xmx2G @user_jvm_args.txt \
     @libraries/net/minecraftforge/forge/1.20.1-47.4.16/unix_args.txt nogui
# 结果写 c4-selftest-report.txt，日志出现 [C4][SelfTest] RESULT: PASS
```

1.7.5 的自检基线：**162 项全 PASS**；`tools/verify_jar.py` **229 项 PASS**。

---

## 4. 版本与保留策略

- 每个快照 = 一个 **Git tag + 同名 Release**；tag 一旦发布不再修改，新内容进新 tag。
- 大文件只进 Release，仓库里只放文本/脚本/小图（当前仓库 < 10 MB）。
- `manifest.json` 是机器可读索引：`path / bytes / sha256 / kind(git|release|external) / note`。
- 恢复时以 `SHA256SUMS.txt` 为准；任何校验失败都视为快照损坏，重新下载即可。

## 5. 许可

- 模组本体与其资源：MIT（原作者 qisumei，移植/重构 nimshade）。
- 本仓库内的脚本、文档：随模组同一许可。
