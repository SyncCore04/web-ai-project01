-- 数据库基础语法的复习
-- 图形化软件：DataGrip
-- 数据库：MySQL
-- 数据库源：localhost:3306

create database if not exists test_db;

show tables ;
use test_db;

create table user(
    id int comment '用户id',
    username varchar(50) comment '用户名',
    name varchar(10) comment '姓名',
    age int comment '年龄',
    gender char(1) comment '年龄'
) comment '用户信息';

ALTER TABLE `user` MODIFY COLUMN gender CHAR(1) COMMENT '性别';

drop table user;

-- 创建新表(带约束)
create table user(
    id int primary key auto_increment comment '用户id', -- 主键:唯一且非空 auto_increment:自动递增
    username varchar(50) not null unique comment '用户名', -- 唯一且非空(其实也是主键的一种情况)
    name varchar(10) not null comment '姓名',
    age int not null comment '年龄',
    gender char(1) not null comment '性别'
) comment '用户信息';

INSERT INTO test_db.user (username, name, age, gender)
    VALUES ('Tom', '汤姆', 18, '男');

INSERT INTO test_db.user (username, name, age, gender)
    VALUES ('Rose', '罗斯', 19, '女');

INSERT INTO test_db.user (username, name, age, gender)
    VALUES ('Weili', '伟丽', 20, '女');



