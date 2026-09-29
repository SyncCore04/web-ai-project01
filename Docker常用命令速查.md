# Docker 常用命令速查

> 面向「用 Docker 跑数据库」的实战速查。**按你要做的事组织，不按命令名字母序。**
> 标注 ✅ 的是 2026-09-28 ~ 29 在你本机实测跑通的（含真实回显），不是你抄来的。

---

## 0. 你的环境（现成可用）

| 项 | 值 |
|---|---|
| 引擎 | Docker Desktop **29.8.0**，跑在隐藏的 `docker-desktop` WSL2 发行版里 |
| compose | **v5.5.1** |
| 容器 1 | `mysql-wsl` — `mysql:8.0.46`，`127.0.0.1:3307` → 容器 3306，healthy |
| 容器 2 | `wayfare-redis` — `redis:7-alpine`，`6379` |
| compose 项目 | `mysql-on-wsl`，文件在 `D:\JavaWeb\study\web-ai-project01\mysql-on-wsl\` |
| 数据卷 | `mysql-on-wsl_mysql-data`（物理上在 WSL2 虚拟磁盘内，**不在你项目目录里**） |
| 网络 | `mysql-on-wsl_default`（bridge） |
| 账号 | `root` / `root123456`；`dev` / `dev123456`（库 `demo_db`） |

**前置检查** —— Docker Desktop 没启动的话，所有命令都会报 `cannot find the file specified`：

```powershell
docker version
```

### ⚠️ 第一条铁律：`docker compose` 要在项目目录里跑

```powershell
cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl
```

否则报 `no configuration file provided: not found`。不想 cd 就加 `-f` 指定文件：

```powershell
docker compose -f D:\JavaWeb\study\web-ai-project01\mysql-on-wsl\docker-compose.yml ps
```

### 容器名 vs 服务名（新手最容易混）

同一套东西有两个名字，不同命令用不同的：

| 标识 | 值 | 用在 |
|---|---|---|
| **服务名** | `mysql` | `docker compose exec mysql ...` |
| **容器名** | `mysql-wsl` | `docker exec -it mysql-wsl ...` |

---

## 1. 数据库日常操作（最高频）

### 1.1 启动 / 停止 / 重启

```powershell
cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl

docker compose up -d        # 启动（-d = 后台运行）
docker compose stop         # 停止，保留容器和数据
docker compose start        # 把已存在的容器再启动（比 up 快）
docker compose restart      # 重启
docker compose down         # 停止并删除容器+网络（数据卷保留）
docker compose down -v      # ⚠️ 连数据卷一起删 = 清库重来
```

`up -d` 与 `start` 的区别：**改过 `docker-compose.yml` 就用 `up -d`**（它会按 yml 重新核对配置）；`start` 只是把现存容器再拉起来。

### 1.2 看状态

```powershell
docker compose ps                       # 本项目容器
docker ps                               # 所有运行中的容器
docker ps -a                            # 含已停止的
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"    # 自定义列
```

必须看到 **`(healthy)`** 才算真就绪。`(health: starting)` 是初始化中，首次要 20–40 秒，**别急着重启**。

### 1.3 连数据库 —— 三种方式

**方式 A：从 Windows 直接用客户端**（GUI 工具也是这套参数）

```powershell
mysql -h 127.0.0.1 -P 3307 -u dev -pdev123456 -D demo_db -e "SELECT * FROM t_user;"
```

> `mysql` 已在 PATH（`C:\Program Files\MySQL\MySQL Server 8.0\bin`），直接敲就行。
> **`-P` 大写是端口，小写 `-p` 是密码** —— 这两个搞反是经典事故。

**方式 B：进容器的 SQL shell**

```powershell
docker compose exec mysql mysql -uroot -proot123456
# 或
docker exec -it mysql-wsl mysql -uroot -proot123456
```

退出：`EXIT;` 或 Ctrl+D。

**方式 C：进容器的 Linux shell**（要翻文件、看日志文件时用）

```powershell
docker exec -it mysql-wsl bash
```

镜像基于 Oracle Linux，**自带 bash**（已实测）。

### 1.4 看日志 / 排错

```powershell
cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl

docker compose logs --tail=80 mysql              # 最后 80 行
docker compose logs -f mysql                     # 实时跟随（Ctrl+C 退出）
docker compose logs mysql | Select-String "ERROR|Warning"
```

中文显示乱码时先 `chcp 65001`。

### 1.5 备份 / 恢复（✅ 已实测完整往返，中文无损）

**备份** —— 关键点：**别用 PowerShell 的 `>` 重定向**。PS 5.1 默认按 UTF-16 写文件，会把备份文件搞坏（也不报错，静默损坏）。
正解是让 `mysqldump` 自己写文件（`--result-file`），再 `docker cp` 拿出来：

```powershell
# 1) dump 到容器内
docker exec mysql-wsl mysqldump -uroot -proot123456 --default-character-set=utf8mb4 --result-file=/tmp/backup.sql demo_db

# 2) 从容器拷到 Windows
docker cp mysql-wsl:/tmp/backup.sql .\demo_db-backup.sql

# 3) 清掉容器里的临时文件
docker exec mysql-wsl rm -f /tmp/backup.sql
```

如果你在 **CMD**（不是 PowerShell）里操作，直接重定向也是安全的（CMD 是字节级重定向）：

```cmd
docker exec mysql-wsl mysqldump -uroot -proot123456 --default-character-set=utf8mb4 demo_db > demo_db-backup.sql
```

**恢复**：

```powershell
docker cp .\demo_db-backup.sql mysql-wsl:/tmp/backup.sql
docker exec -it mysql-wsl mysql -uroot -proot123456 --default-character-set=utf8mb4 demo_db -e "source /tmp/backup.sql"
```

**实测证据**（2026-09-29，完整走了一遍 dump → restore 到新库 → 校验 HEX → 清理）：

```
[1] dump OK          2093 /tmp/b.sql
[2] restore OK
id  name  hex
1   张三  E5BCA0E4B889     ← 与源库 HEX 完全一致，中文零损失
2   李四  E69D8EE59B9B
3   阿布  E998BFE5B883
[3] cleanup OK
```

> `--default-character-set=utf8mb4` 这个参数**必须带**。不带的话，客户端可能按 latin1 处理，中文会像 `init/01-init.sql` 那样被双重编码 —— 详见 `mysql-on-wsl/README.md` 第 5.9 节。

### 1.6 彻底重置（⚠️ 会删数据）

```powershell
cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl
docker compose down -v      # -v 删数据卷 = 数据全没
docker compose up -d        # 重新初始化，init/*.sql 会重跑
```

适合「练手把库搞乱了，想回到干净状态」。**⚠️ 有真实数据先备份。**

### 1.7 看资源占用

```powershell
docker stats                    # 实时刷新（Ctrl+C 退出）
docker stats --no-stream        # 只取一次快照
docker compose stats
```

---

## 2. 新建一个项目专属数据库

原则：**每个项目一套 compose，换个宿主端口**，互不干扰。

1. 复制模板目录：`mysql-on-wsl` → `<你的项目>\docker\`
2. 改 `docker-compose.yml` 三处：

   | 字段 | 改成 |
   |---|---|
   | `container_name` | `mysql-<项目名>` |
   | `ports` | `"127.0.0.1:3308:3306"`（下一套用 3308、3309…） |
   | `MYSQL_ROOT_PASSWORD` | 你自己的密码 |

3. 改 `init/01-init.sql` 的库名与表结构 —— **第一行 `SET NAMES utf8mb4;` 千万别删**
4. `docker compose up -d`

**端口冲突排查**：

```powershell
Get-NetTCPConnection -LocalPort 3308 -State Listen | Select-Object OwningProcess
```

**端口分配建议**：3307 已用 → 新项目依次 3308 / 3309 / 3310，别回头去抢 3306（那是 Windows 原生 MySQL80）。

---

## 3. 容器通用命令

| 目的 | 命令 |
|---|---|
| 列出运行中 | `docker ps` |
| 列出全部（含停止） | `docker ps -a` |
| 启动 / 停止 / 重启 | `docker start <名>` / `stop` / `restart` |
| 删除已停止容器 | `docker rm <名>` |
| 强制删除运行中 | `docker rm -f <名>` |
| 看日志 | `docker logs --tail=100 -f <名>` |
| 进 shell | `docker exec -it <名> bash` |
| 在容器里跑一条命令 | `docker exec <名> <命令>` |
| 看端口映射 | `docker port <名>` |
| 看容器内进程 | `docker top <名>` |
| 看配置详情 | `docker inspect <名>` |
| 只看挂载信息 | `docker inspect <名> --format "{{json .Mounts}}"` |
| 容器 → 本机 | `docker cp <名>:/路径 ./本地` |
| 本机 → 容器 | `docker cp ./本地 <名>:/路径` |
| 看容器文件系统改动 | `docker diff <名>` |

---

## 4. 镜像命令

| 目的 | 命令 |
|---|---|
| 列出镜像 | `docker images` |
| 拉取 | `docker pull mysql:8.0` |
| 搜索 | `docker search mysql` |
| 删除 | `docker rmi mysql:8.0` |
| 看构建层 | `docker history mysql:8.0` |
| **临时跑一次就删**（很实用） | `docker run --rm mysql:8.0 mysqldump --version` |

**版本选择**：

| Tag | 说明 |
|---|---|
| `mysql:8.0` | ✅ 你当前用的，最稳，老客户端兼容最好 |
| `mysql:8.4` | LTS，但默认认证插件变了，老 Navicat/JDBC 驱动可能连不上 |
| `mysql:5.7` | 跟着老教程走时用 |

---

## 5. 数据卷命令

卷是**数据的真正所在** —— 不在你的项目目录里。

| 目的 | 命令 |
|---|---|
| 列出 | `docker volume ls` |
| 看详情（含物理路径） | `docker volume inspect mysql-on-wsl_mysql-data` |
| 删除指定卷 ⚠️ | `docker volume rm <卷名>` |
| 清理无主卷 ⚠️⚠️ | `docker volume prune` |

> `docker volume inspect` 会显示 `Mountpoint` 是 `/var/lib/docker/volumes/...` —— 那是**容器内视角**的路径，在 WSL2 虚拟磁盘里，Windows 资源管理器打不开。

---

## 6. 网络命令

| 目的 | 命令 |
|---|---|
| 列出 | `docker network ls` |
| 看详情 | `docker network inspect mysql-on-wsl_default` |
| 删除 | `docker network rm <名>` |
| 清理无主网络 | `docker network prune` |

**容器之间的 DNS**：同一个 compose 网络里，容器可以直接用**容器名**互相访问（✅ 已实测）。

```powershell
docker run --rm --network mysql-on-wsl_default mysql:8.0 mysql -hmysql-wsl -uroot -proot123456 -e "SELECT 1"
```

这个能力以后做多服务项目（app 容器 + db 容器 + redis 容器）时是基础 —— **app 里连数据库不用写 IP，直接写容器名 `mysql-wsl` 就行。**

---

## 7. compose 命令一览

```powershell
docker compose ls -a                # 列出所有 compose 项目
docker compose config               # 校验并展开 yml（不需要引擎也能跑）
docker compose config --quiet       # 只校验，无输出 = 通过
docker compose up -d                # 创建并启动
docker compose up -d --build        # 先重建镜像再启动
docker compose down                 # 停止并删除容器 + 网络
docker compose down -v              # ⚠️ 连数据卷一起删
docker compose ps                   # 状态
docker compose logs -f mysql        # 日志
docker compose exec mysql bash      # 进容器
docker compose restart mysql        # 重启单个服务
docker compose pull                 # 拉新镜像
docker compose top                  # 容器内进程
docker compose images               # 本项目用到的镜像
docker compose volumes              # 本项目用到的卷
```

---

## 8. ⚠️ 危险命令红榜

**跑之前停三秒，确认你知道自己在删什么：**

| 命令 | 后果 |
|---|---|
| `docker compose down -v` | 删数据卷 = **数据全没** |
| `docker volume rm <名>` | 同上 |
| `docker volume prune` | 删**所有**无主卷 —— 容器停着的项目数据也会没了 |
| `docker system prune -a` | 删所有未使用镜像/容器/网络。**加 `--volumes` 连卷一起删** |
| `docker rm -f <名>` | 强杀运行中容器（数据在卷里，一般安全，但可能丢未落盘的写入） |
| `docker rmi -f <镜像>` | 强删镜像，可能连带出问题 |

**铁律：删除类命令之前，先备份。**

```powershell
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
docker exec mysql-wsl mysqldump -uroot -proot123456 --default-character-set=utf8mb4 --result-file=/tmp/b.sql demo_db
docker cp mysql-wsl:/tmp/b.sql "D:\backup\demo_db-$ts.sql"
docker exec mysql-wsl rm -f /tmp/b.sql
```

---

## 9. 磁盘清理（安全版）

```powershell
docker system df                    # 先看占用
docker system df -v                 # 看每个对象明细
docker image prune                  # 只删悬空镜像（安全）
docker container prune              # 只删已停止容器（安全）
docker builder prune                # 清构建缓存
docker system prune                 # 未使用容器+网络+悬空镜像（不加 -a 较安全）
```

**你当前占用**（2026-09-29 实测）：

```
TYPE            TOTAL     ACTIVE    SIZE       RECLAIMABLE
Images          4         2         1.172GB    13.04MB (1%)
Containers      2         2         45.06kB    0B
Local Volumes   2         2         210.4MB    0B
```

镜像 1.17 GB 里大头是 `mysql:8.0` 的 **1.1 GB** —— 正常，别删。
另外你还有 `hello-world`（25.9 kB）和 `alpine`（13 MB）两个用不上的，`docker rmi` 掉就行。

---

## 10. 效率配置（可选，一次配置长期省事）

### PowerShell 快捷函数

先查 profile 路径：

```powershell
$PROFILE
```

把下面加进那个文件：

```powershell
function dk    { docker @args }
function dkc   { docker compose -f D:\JavaWeb\study\web-ai-project01\mysql-on-wsl\docker-compose.yml @args }
function dksql { docker exec -it mysql-wsl mysql -uroot -proot123456 @args }
```

新开一个 PowerShell 窗口后，从**任何目录**都能用：

```powershell
dkc ps
dkc logs --tail=50 mysql
dkc down
dksql -e "SHOW DATABASES;"
```

### Docker Desktop 开机自启

数据库的可用性依赖 Docker Desktop 在运行，而它**默认不随开机自启**。
建议在 Docker Desktop → Settings → General 里打开开机启动，省掉「代码突然连不上，一查是 Docker 没开」这个摩擦。

---

## 11. 排错速查

| 现象 | 原因 / 解法 |
|---|---|
| `failed to connect to the docker API at npipe:...` | Docker Desktop 没启动 |
| `no configuration file provided: not found` | 没 cd 进项目目录，见第 0 节 |
| `port is already allocated` | 端口被占，见 1.7 / 第 2 节 |
| 一直 `(health: starting)` | 首次初始化 20–40 秒；超时看 `docker compose logs` |
| 中文乱码 `?????‰` | **先查 HEX 判断是数据层还是显示层**，见 `mysql-on-wsl/README.md` 第 5.9 节 |
| `Access denied for user` | 密码错，或账号 host 不匹配（`'dev'@'%'` vs `'dev'@'localhost'`） |
| `Public Key Retrieval is not allowed` | JDBC 串缺 `allowPublicKeyRetrieval=true` |
| `server time zone value ... is unrecognized` | JDBC 串缺 `serverTimezone=Asia/Shanghai` |
| `no space left on device` | `docker system df` 看占用，再按第 9 节清 |

---

## 12. 一句话备忘

```text
起库   cd mysql-on-wsl && docker compose up -d
看状态 docker compose ps          （要看到 healthy）
连库   mysql -h 127.0.0.1 -P 3307 -u dev -pdev123456 -D demo_db
进 SQL docker exec -it mysql-wsl mysql -uroot -proot123456
日志   docker compose logs -f mysql
备份   mysqldump --result-file=/tmp/b.sql  →  docker cp 出来
重置   docker compose down -v && docker compose up -d    ⚠️ 删数据
```
