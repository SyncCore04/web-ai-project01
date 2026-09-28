# 在 WSL2 上跑 MySQL，并从 Windows 本机连接

> 目标：宿主（Windows）用 `127.0.0.1:3307` 连到 WSL2 里的 MySQL，且**不影响**你 Windows 上已有的 MySQL80（占着 3306）。

> ### ⚠️ 执行前必读：所有 `docker compose` 命令都必须先 `cd` 进本目录
>
> ```powershell
> cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl
> ```
>
> 否则会报 **`no configuration file provided: not found`**。
> Compose 是按**当前工作目录**去找 `docker-compose.yml` 的，你在 `C:\Users\Apollo` 下执行它当然找不到。
> （这不是 MySQL 出错，容器其实活得好好的。）
> 不想 `cd` 就用 `-f` 显式指定文件，详见 [5.7](#57-no-configuration-file-provided-not-found)。

> ### ⚠️ 中文乱码 ≠ 控制台问题，先查 HEX
>
> 如果中文显示成 `?????‰` 这种，**别急着调控制台编码** —— 大概率是数据本身被双重编码了。
> 判定命令与完整原理见 **第 5.9 节**。这个坑在你以后自己写 SQL 文件导入数据时**会再踩一次**。

---

## 0. 先说四条红字

**✅ 1. Docker Desktop —— 2026-09-28 22:38 已确认启动，引擎 Server 29.8.0 正常。**
（初版写这一条时我探测到 `dockerDesktopLinuxEngine` 管道不存在、引擎是关着的。现在已不需要处理，留作记录。）
后续若哪天连不上，第一件事仍是确认 Docker Desktop 在运行 —— 它不会随开机自动起。

**🔴 2. Docker Desktop 跑的容器，物理上不在 `Ubuntu` 那个发行版里。**
Docker Desktop 有自己隐藏的 WSL2 发行版（`docker-desktop`），容器住在那里。
对你的需求（Windows 连一个 Linux 上的 MySQL）**结果完全一样**，端口转发也一样，
但你要知道「我并没有把 MySQL 装进 Ubuntu」这件事。
如果你确实要装在 Ubuntu 里，看 [附录 A](#附录-a-改为装在-ubuntu-发行版里)。

**🔴 3. 3306 已经被 Windows 原生 MySQL80 占着，所以这里刻意用 3307。**
WSL2 默认是 NAT 网络模式，Windows 的 `localhost` 转发会优先命中 Windows 自己监听的那个端口。
你要是让 WSL 里的 MySQL 也去抢 3306，会得到「能连上、但连的是另一个库」这种最难查的 bug。

**🔴 4. 所有 `docker compose` 命令先 `cd` 进本目录。**
否则报 `no configuration file provided: not found` —— 见文首警示框与 [5.7](#57-no-configuration-file-provided-not-found)。
这个错看着像服务挂了，其实容器完全正常，纯粹是找错了目录。

---

## 1. 端口与凭据规划（已按你的选择定好）

| 项 | 值 |
|---|---|
| 容器内端口 | `3306` |
| **Windows 访问端口** | **`3307`**（只绑 `127.0.0.1`，不暴露给局域网） |
| root 密码 | `root123456` |
| 业务账号 | `dev` / `dev123456` |
| 初始库 | `demo_db`（utf8mb4，内含样例表 `t_user`） |
| Windows 上原有 MySQL80 | `3306`，**不动** |
| 数据持久化 | Docker 命名卷 `mysql-on-wsl_mysql-data` |

---

## 2. 文件清单

已经生成在 `D:\JavaWeb\study\web-ai-project01\mysql-on-wsl\`：

| 文件 | 作用 |
|---|---|
| `docker-compose.yml` | 服务定义（已验证 `docker compose config` 通过） |
| `init/01-init.sql` | 首次启动自动建库建用户建样例表 |
| `start-mysql.bat` | 一键：检查引擎 → 启动 → 等健康 → 打印连接信息 |
| `verify-connection.bat` | 一键：用你本机已有的 `mysql.exe` 从 Windows 侧验证连通性 |

---

## 3. 执行步骤

### 步骤 1 —— 启动 Docker Desktop
手动打开即可。等托盘图标变绿 / 界面显示 **Engine running**。

验证（PowerShell 或 CMD）：

```powershell
docker version
```

**预期**：能看到 `Server: Docker Desktop ... Engine: Version: 2x.x.x`。
只要出现 `failed to connect to the docker API at npipe:...` 就说明引擎还没起来，别继续。

---

### 步骤 2 —— 启动 MySQL

**方式 A（推荐，双击）**：进目录双击 `start-mysql.bat`。

**方式 B（命令行）**：

```powershell
cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl
docker compose up -d
```

**预期输出末尾**：

```
[+] Running 3/3
 ✔ Network mysql-on-wsl_default  Created
 ✔ Volume "mysql-on-wsl_mysql-data"  Created
 ✔ Container mysql-wsl           Started
```

> 首次会拉 `mysql:8.0` 镜像（约 150 MB，视网速）。
> 想加速可在 Docker Desktop → Settings → Docker Engine 里加国内镜像源，或预先 `docker pull mysql:8.0`。

---

### 步骤 3 —— 等到健康

```powershell
docker compose ps
```

**预期**：

```
NAME        IMAGE       STATUS                   PORTS
mysql-wsl   mysql:8.0   Up 40 seconds (healthy)  127.0.0.1:3307->3306/tcp
```

`STATUS` 里出现 **(healthy)** 才算就绪。首次启动初始化数据目录要 20–40 秒，
期间是 `(health: starting)`，**这是正常的，别急着重启** —— 重启反而可能让 init 脚本半途而废。

如果一直不 healthy，看日志：

```powershell
docker compose logs --tail=80 mysql
```

---

### 步骤 4 —— 确认 init 脚本跑过

```powershell
cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl
docker compose logs --tail=300 mysql | Select-String "01-init.sql|ready for connections"
```

**实测预期输出**（2026-09-28 真实回显）：

```
mysql-wsl  | 2026-09-28 22:35:28+08:00 [Note] [Entrypoint]: /usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/01-init.sql
mysql-wsl  | 01-init.sql 执行完毕
mysql-wsl  | 2026-09-28T14:35:31.048366Z 0 [System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '8.0.46'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL.
```

> 若中文显示成 `鎵ц瀹屾瘯` 这类乱码，是 Windows 控制台代码页的问题（不是数据坏了）。
> 执行 `chcp 65001` 切到 UTF-8 再看，或改用 `--default-character-set=gbk` 连接。

**日志里出现下面这些 Warning 都是正常的，别慌：**

| 日志内容 | 说明 |
|---|---|
| `The syntax '--skip-host-cache' is deprecated` | 镜像自带 my.cnf 里的写法，非本方案引入 |
| `root@localhost is created with an empty password` | 来自**初始化用的临时实例**，不是最终状态。最终 root 密码就是你设的那个（用 `-proot123456` 能登进去即为证） |
| `CA certificate ca.pem is self signed` | 容器自签证书，本地环境正常 |
| `Insecure configuration for --pid-file` | 容器内 `/var/run/mysqld` 权限宽松，正常 |
| `Unable to load '/usr/share/zoneinfo/...' as time zone` | 见 [5.8](#58-报-unknown-or-incorrect-time-zone-asisshanghai) —— 正是这条促使本方案改用 `+08:00` 偏移量 |

---

### 步骤 5 —— 从 Windows 本机验证

**双击 `verify-connection.bat`**，或在 PowerShell 里手敲：

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -h 127.0.0.1 -P 3307 -u root -proot123456 `
  -e "SELECT VERSION(), @@port, @@character_set_server, @@time_zone;"
```

**预期输出**：

```
+-----------+--------+------------------------+-----------+
| VERSION() | @@port | @@character_set_server | @@time_zone |
+-----------+--------+------------------------+-----------+
| 8.0.xx    |   3306 | utf8mb4                | +08:00     |
+-----------+--------+------------------------+-----------+
```

> ⚠️ `@@port` 显示 **3306** 是对的！那是**容器内部**的端口，`3307` 只是宿主的转发口。
> 很多人在这里以为配错了 —— 没配错。

再验证业务账号和中文：

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -h 127.0.0.1 -P 3307 -u dev -pdev123456 -D demo_db -e "SELECT * FROM t_user;"
```

**预期**：三行数据，`张三` / `李四` / `阿布` 显示正常（不是乱码、不是 `???`）。

> 客户端会往 stderr 打一句 `Using a password on the command line interface can be insecure.`
> 这是 `mysql.exe` 的固定警告，**不是错误**，忽略。

---

### 步骤 6 —— 连进交互式 shell（可选）

```powershell
docker exec -it mysql-wsl mysql -uroot -proot123456
```

**预期**：出现 `mysql>` 提示符。

```sql
SHOW DATABASES;
SELECT @@hostname, @@port, NOW();
EXIT;
```

`@@hostname` 会是一串容器 ID —— 这就是「我连的确实是另一个机器上的实例」的铁证。

---

## 4. 接到 IDEA / Navicat / Spring Boot

### 通用连接参数

| 字段 | 值 |
|---|---|
| Host | `127.0.0.1` |
| Port | **`3307`** |
| User | `dev`（业务）或 `root`（管理） |
| Password | `dev123456` / `root123456` |
| Database | `demo_db` |

### Spring Boot `application.yml`

```yaml
spring:
  datasource:
    url: jdbc:mysql://127.0.0.1:3307/demo_db?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
    username: dev
    password: dev123456
    driver-class-name: com.mysql.cj.jdbc.Driver
```

**三个参数不能省，都是踩过的坑：**

| 参数 | 不写会怎样 |
|---|---|
| `serverTimezone=Asia/Shanghai` | 报 `The server time zone value '?D1ú±ê×?ê±??' is unrecognized`（容器默认 UTC + 中文 locale 乱码） |
| `allowPublicKeyRetrieval=true` | 报 `Public Key Retrieval is not allowed`（MySQL 8 默认 `caching_sha2_password` + 非 SSL 连接） |
| `useSSL=false` | 一堆 SSL 握手警告刷屏 |

### Navicat / DBeaver / IDEA 自带客户端

Host 填 `127.0.0.1`，端口填 **`3307`**，其余同上。
若客户端版本太老不认 `caching_sha2_password`，连不上时按 [5.4](#54-老客户端连不上caching_sha2_password) 处理。

---

## 5. 常见坑

### 5.1 改了 `init/01-init.sql` 却不生效
`docker-entrypoint-initdb.d` 里的脚本**只在数据卷为空时执行一次**。
所以改完 SQL 必须把卷删掉重来：

```powershell
docker compose down -v      # ⚠️ -v 会删除 mysql-data 卷，数据全没
docker compose up -d
```

**只在确认 demo 数据可以丢弃时这么干。** 有真实数据时，用 `docker exec` 进去手工执行 SQL。

### 5.2 3307 也报 `port is already allocated`
说明 3307 被别的东西占了。查：

```powershell
Get-NetTCPConnection -LocalPort 3307 -State Listen | Select-Object OwningProcess
Get-Process -Id <上面拿到的PID>
```

换个口即可 —— 同时改 `docker-compose.yml` 的 `ports` 和所有连接串里的端口号。

### 5.3 想让别的电脑 / 手机连
把 `docker-compose.yml` 里的

```yaml
- "127.0.0.1:3307:3306"
```
改成
```yaml
- "3307:3306"
```

然后 Windows 防火墙放行 3307，别人用你的局域网 IP（本次探测到以太网是 `192.168.1.169`）连。

⚠️ **这么改之后 `root` 就暴露在局域网了**，务必改掉 `root123456` 这种弱密码，
或者干脆删掉 root 的远程访问、只留 `dev` 账号。别在公共 WiFi 下这么干。

### 5.4 老客户端连不上（caching_sha2_password）
MySQL 8 默认认证插件是 `caching_sha2_password`，Navicat 15 以下、旧版 JDBC 驱动不认。
两个解法，**优先选第一个**：

```sql
-- 解法 1：升级客户端 / 把 JDBC 驱动升到 8.0.30+（推荐）
-- 解法 2：改这个账号的认证方式（仅限本地学习环境）
ALTER USER 'dev'@'%' IDENTIFIED WITH mysql_native_password BY 'dev123456';
FLUSH PRIVILEGES;
```

### 5.5 WSL 重启后连不上
只要容器在跑，`127.0.0.1:3307` 就一直有效 —— Docker Desktop 会自动把端口转发到宿主，
**不需要记 WSL 的 IP**，也不受 WSL IP 每次重启变化的影响。这是选 Docker 方案而不是 apt 方案的一个实际好处。

若连不上，先确认 `docker compose ps` 里是 `Up (healthy)`。

### 5.6 和 Windows 原生 MySQL80 分不清
在客户端里执行：

```sql
SELECT @@hostname, @@version_comment, @@port;
```

- `@@hostname` 是容器 ID 一串十六进制 → WSL 里这套
- `@@hostname` 是你的 Windows 机器名 → 原生 MySQL80

建议在 Navicat / IDEA 里把两个连接**分别命名**为「WSL-MySQL-3307」和「Win-MySQL-3306」，别再靠端口猜。

### 5.7 `no configuration file provided: not found`
**这是最容易踩的一个，而且极具误导性 —— 它不是 MySQL 的问题，容器可能活得好好的。**

原因：`docker compose` 只会在**当前工作目录**里找 `docker-compose.yml`。
如果你在 `C:\Users\Apollo`（或任何别的目录）下执行，它找不到文件，就报这个错。

```powershell
# 现象
PS C:\Users\Apollo> docker compose logs mysql
no configuration file provided: not found
```

**解法 1（推荐）：先 cd 进目录**

```powershell
cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl
docker compose logs --tail=80 mysql
```

**解法 2：用 `-f` 显式指定文件，可从任意目录执行**

```powershell
docker compose -f D:\JavaWeb\study\web-ai-project01\mysql-on-wsl\docker-compose.yml logs --tail=80 mysql
```

**解法 3：设个 PowerShell 快捷函数（一次配置，长期省事）**

先看你的 profile 路径：

```powershell
$PROFILE
```

在该文件里加：

```powershell
function wsmysql { docker compose -f D:\JavaWeb\study\web-ai-project01\mysql-on-wsl\docker-compose.yml @args }
```

重新开一个 PowerShell 窗口，然后从**任何目录**都能直接：

```powershell
wsmysql ps
wsmysql logs --tail=80 mysql
wsmysql down
```

> **判据**：只要 `docker ps -a` 里 `mysql-wsl` 是 `Up (healthy)`，
> 那这个 compose 报错就纯粹是「站错了目录」，跟服务状态无关。

### 5.8 报 `Unknown or incorrect time zone: 'Asia/Shanghai'`
日志里那句 `Unable to load '/usr/share/zoneinfo/...' as time zone. Skipping it.`
意味着 MySQL 的**时区名称表没被填充**，所以服务端不认 `Asia/Shanghai` 这种**名称**，只认 `+08:00` 这种**偏移量**。

- 本方案的 `docker-compose.yml` 里写的就是 `--default-time-zone=+08:00`，所以服务端没问题（实测 `@@time_zone = +08:00` ✅）。
- JDBC 串里的 `serverTimezone=Asia/Shanghai` 是**驱动侧**的解析参数，由驱动自己做换算，不需要服务端时区表，所以也不会报错。
- **只有**你在 SQL 里手写 `SET time_zone='Asia/Shanghai';` 时才会撞上。此时：

```sql
SET time_zone = '+08:00';   -- 用偏移量，一定能成
```

真要支持名称，需进容器填充时区表：

```powershell
docker exec -it mysql-wsl mysql_tzinfo_to_sql /usr/share/zoneinfo | docker exec -i mysql-wsl mysql -uroot -proot123456 mysql
```

### 5.9 中文乱码（已定位并修复）

**现象**：查 `t_user` 看到 `?????‰`、`é?????` 这类东西。

**结论先行：这不是控制台显示问题，是数据在写入时就坏了。**
一开始我也以为是控制台代码页问题，去查了 HEX 才发现真相比乱码更严重 —— **中文被双重编码入库了。**

#### 判定方法：直接看底层字节，一锤定音

```sql
SELECT id, name, HEX(name) AS hex, CHAR_LENGTH(name) AS chars, LENGTH(name) AS bytes FROM t_user;
```

| 情况 | 「张三」的 HEX | chars | bytes |
|---|---|---|---|
| ✅ 正确 | `E5BCA0E4B889` | 2 | 6 |
| ❌ 双重编码 | `C3A5C2BCC2A0C3A4C2B8E280B0` | 6 | 13 |

第二种是字符串 `å¼ ä¸‰` 的 UTF-8 编码 —— 也就是**「张三」的 UTF-8 字节被当成 latin1 解读了一遍**。

#### 根因

`init/*.sql` 是 UTF-8 文件，而容器 entrypoint 执行它时，**`mysql` 客户端的默认 charset 是 `latin1`（不是 utf8mb4）**。
于是服务端把文件里的 UTF-8 字节按 latin1 解读成 6 个「拉丁字母」，再以 utf8mb4 存进库 → 双重编码。
`character_set_server` 显示 utf8mb4 是**正常的**，问题出在客户端那一侧。

#### 修复（已生效）

`init/01-init.sql` 最前面加了这一行，**不要删**：

```sql
SET NAMES utf8mb4;
```

#### 验证方式

另起一个一次性容器，挂**同一份** init 目录，走真实 entrypoint 流程，再查 HEX。
2026-09-28 实测：

```
id  name  hex             chars  bytes
1   张三  E5BCA0E4B889    2      6
2   李四  E69D8EE59B9B    2      6
3   阿布  E998BFE5B883    2      6
```

全部 2 字符 / 6 字节 ✅

#### 你以后自己导 SQL 文件时会再踩这个坑

```powershell
# 解法 1（推荐）：导入时显式声明客户端编码
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -h 127.0.0.1 -P 3307 -u root -proot123456 `
  --default-character-set=utf8mb4 demo_db < your.sql

# 解法 2：在 SQL 文件最前面加 SET NAMES utf8mb4;   或给中文字面量加 introducer
INSERT INTO t_user (name) VALUES (_utf8mb4'张三');
```

#### 如果库里已经有坏数据，就地修复（不必删库）

```sql
UPDATE t_user SET name = CONVERT(BINARY(CONVERT(name USING latin1)) USING utf8mb4);
```

原理：把「被误读的那 6 个字符」还原回 latin1 字节 `E5 BC A0 E4 B8 89`，再按 utf8mb4 重新解读。
**修完务必用上面的 HEX 语句复核。**

#### 那控制台显示呢？

你的 PowerShell 是 `CP936`，而 `mysql.exe` 客户端的默认 charset 正好也是 `gbk`，本来就对得上。
**所以数据修好之后，原来那条命令直接就能显示正常中文，不需要加任何参数。**
只有当你显式把客户端切到 utf8mb4 时，才需要配套：

```powershell
chcp 65001
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

---

## 6. 日常运维命令

**先 `cd` 进目录**（或按 [5.7](#57-no-configuration-file-provided-not-found) 的解法 2/3 免 cd）：

```powershell
cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl
```

```powershell
docker compose ps                          # 看状态
docker compose stop                        # 停（保留容器和数据）
docker compose start                       # 启
docker compose down                        # 删容器和网络（保留数据卷）
docker compose down -v                     # ⚠️ 连数据一起删
docker compose logs -f --tail=50 mysql     # 实时看日志
docker exec -it mysql-wsl bash             # 进容器
docker exec -it mysql-wsl mysql -uroot -proot123456    # 进 SQL shell
docker stats mysql-wsl                     # 看资源占用
```

### 备份 / 还原

```powershell
# 备份 demo_db 到当前目录
docker exec mysql-wsl mysqldump -uroot -proot123456 --default-character-set=utf8mb4 demo_db > demo_db-backup.sql

# 还原
Get-Content demo_db-backup.sql | docker exec -i mysql-wsl mysql -uroot -proot123456 demo_db
```

> 注意：PowerShell 的 `>` 重定向在 Windows PowerShell 5.1 里默认写成 UTF-16，
> 会让备份文件格式出错。**稳妥做法**是在 CMD 里执行，或显式指定：
> `docker exec ... | Out-File -Encoding utf8 demo_db-backup.sql`
> 更推荐用 `mysqldump ... --result-file=/tmp/x.sql` 导到容器内再 `docker cp` 出来。

---

## 附录 A：改为装在 Ubuntu 发行版里

如果你确实要 MySQL 落在 `Ubuntu` 这个发行版内部（而不是 Docker Desktop 的隐藏发行版），
那得走 apt，且需要两件事：

**A1. 先给 Ubuntu 开 systemd**（否则 `systemctl` 不可用，MySQL 服务起不来）

```bash
sudo tee /etc/wsl.conf > /dev/null <<'EOF'
[boot]
systemd=true
EOF
```

然后在 **Windows** 侧执行 `wsl --shutdown`，再重新进 Ubuntu。

**A2. 装 MySQL 并改端口到 3307**

```bash
sudo apt update
sudo apt install -y mysql-server
sudo systemctl enable --now mysql

# 改端口，避开 Windows 的 3306。Ubuntu 24.04 走 conf.d 片段
sudo tee /etc/mysql/mysql.conf.d/zz-wsl-port.cnf > /dev/null <<'EOF'
[mysqld]
port = 3307
bind-address = 0.0.0.0
character-set-server = utf8mb4
collation-server = utf8mb4_0900_ai_ci
default-time-zone = '+08:00'
EOF

sudo systemctl restart mysql
```

**A3. 建账号 + 授权**

```bash
sudo mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS demo_db
  DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_0900_ai_ci;
CREATE USER IF NOT EXISTS 'dev'@'%' IDENTIFIED BY 'dev123456';
GRANT ALL PRIVILEGES ON demo_db.* TO 'dev'@'%';
FLUSH PRIVILEGES;
SQL
```

**A4. Windows 侧连接**

`127.0.0.1:3307` —— WSL2 默认开启 localhost 转发，不用记 WSL IP。

若连不上（有些环境 localhost 转发不稳），退而用 WSL 的 IP：

```bash
ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
```

用它替换 `127.0.0.1`。缺点是 **WSL 每次重启 IP 都会变**，要重新查 —— 这也是我不推荐这条路的原因。

---

## 附录 B：我探测到的本机环境（供对照排错）

| 项 | 值 |
|---|---|
| OS | Windows 11 家庭版，Build **26200** |
| WSL 发行版 | **Ubuntu**（WSL2）、`docker-desktop` |
| `~/.wslconfig` | 存在但**空白** → 默认 NAT 模式，未开 mirrored |
| 3306 | Windows 原生 `mysqld` 占用（服务 **MySQL80**，Running） |
| 3307 | 空闲 ✅ |
| MySQL 客户端 | `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`（**已在 PATH**） |
| docker compose | v5.5.1 ✅ |
| Docker 引擎 | 探测时**未运行** ⚠️ |

> 顺带一提：你装了 `docker-desktop` 发行版说明 Docker Desktop 早就装好了，
> 这次整个流程的唯一前置动作就是**把它启动起来**。

---

## 一句话流程

```text
启动 Docker Desktop
  → cd D:\JavaWeb\study\web-ai-project01\mysql-on-wsl   ← 这步最容易忘，忘了就报 no configuration file
  → docker compose up -d   （或双击 start-mysql.bat，它会自己 cd）
  → docker compose ps      看到 (healthy)
  → 双击 verify-connection.bat
  → 连接串统一用 127.0.0.1:3307
```

---

## 实测验收记录（2026-09-28）

本机真实回显，证明链路已通：

```text
$ docker version --format "Server={{.Server.Version}}"
Server=29.8.0

$ docker ps -a --format "{{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}"
mysql-wsl    | mysql:8.0   | Up 3 minutes (healthy) | 127.0.0.1:3307->3306/tcp
wayfare-redis| redis:7-alpine | Up 5 minutes        | 0.0.0.0:6379->6379/tcp

$ mysql.exe -h 127.0.0.1 -P 3307 -u root -proot123456 -e "SELECT VERSION(), @@port, @@character_set_server, @@time_zone, @@hostname;"
version  port  charset  collation            tz       hostname
8.0.46   3306  utf8mb4  utf8mb4_0900_ai_ci  +08:00   9748820a6430

$ mysql.exe -h 127.0.0.1 -P 3307 -u dev -pdev123456 -D demo_db -e "SELECT COUNT(*) FROM t_user;"
3
```

要点：
- `@@port = 3306` 是**容器内部**端口，宿主转发口是 3307 —— 正常，别改。
- `@@hostname = 9748820a6430` 是容器 ID → 确认连的是 WSL 里这套，不是 Windows 原生 MySQL80。
- `@@time_zone = +08:00` → 时区参数生效，JDBC 那个 `server time zone value` 报错不会出现。
- 你机器上还跑着一个 `wayfare-redis` 容器，与本方案无关，但说明 Docker 环境本身是好的。
