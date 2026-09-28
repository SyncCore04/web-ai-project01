-- ============================================================
--  首次启动初始化脚本
--  ⚠️ 只在数据卷为空时执行一次。改了这里要生效，必须 docker compose down -v 再 up
-- ============================================================

-- ⚠️⚠️ 下面这一行绝对不能删，删了中文就会变乱码 ⚠️⚠️
-- 原因：容器 entrypoint 执行本文件时，用的 mysql 客户端 **默认 charset 是 latin1**。
--      本文件是 UTF-8，如果不说清楚，服务端会把 UTF-8 字节按 latin1 解读，
--      产生「双重编码」再以 utf8mb4 存进去（实测踩过）：
--        正确  张三 -> HEX E5BCA0E4B889   （2 字符 / 6 字节）
--        乱码  'å¼ ä¸‰' -> HEX C3A5C2BCC2A0C3A4C2B8E280B0 （6 字符 / 13 字节）
-- 补充：若不改客户端 charset，也可给每个中文字面量加 introducer，如 _utf8mb4'张三'。
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS demo_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

-- 给应用用的普通账号（Spring Boot / IDEA 里建议用它，而不是 root）
CREATE USER IF NOT EXISTS 'dev'@'%' IDENTIFIED BY 'dev123456';
GRANT ALL PRIVILEGES ON demo_db.* TO 'dev'@'%';
FLUSH PRIVILEGES;

-- 一张最小的样例表，用来验证「连上了、中文字符集也对」
USE demo_db;

CREATE TABLE IF NOT EXISTS t_user (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  name       VARCHAR(50)  NOT NULL COMMENT '姓名',
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

INSERT INTO t_user (name) VALUES ('张三'), ('李四'), ('阿布');

-- 确认落地
SELECT '01-init.sql 执行完毕' AS msg;
SELECT @@port AS container_port, @@character_set_server AS charset, @@time_zone AS tz;
