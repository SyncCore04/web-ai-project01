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


-- 案例：设计员工表 emp
-- 基础字段：id 主键；create_time 创建时间；update_time 修改时间;
create table emp (
    id int unsigned primary key auto_increment comment 'ID, 主键',
    username varchar(20) not null unique comment '用户名',
    password varchar(32) default '123456' comment '密码',
    name varchar(10) not null comment '姓名',
    gender tinyint unsigned not null comment '性别, 1 男; 2 女',
    phone char(11) not null unique comment '手机号',
    job tinyint unsigned comment '职位, 1 班主任; 2 讲师; 3 学工主管; 4 教研主管; 5 咨询师',
    salary int unsigned comment '薪资',
    entry_date date comment '入职日期',
    image varchar(255) comment '图像',
    create_time datetime comment '创建时间',
    update_time datetime comment '修改时间'
) comment '员工表';

-- 查看当前数据库的所有表
show tables;

-- 查看表结构
desc emp;

-- 查看建表语句
show create table emp;

-- 添加字段 qq varchar(10)
alter table emp add qq varchar(10) comment 'QQ号';

-- 修改qq字段为 varchar(15)
alter table emp modify qq varchar(15) comment 'QQ号';

-- 修改qq字段名 qq_num
alter table emp rename column qq to qq_num;

-- 删除qq_num字段
alter table emp drop column qq_num;

-- 修改表 emp rename to employee;
alter table emp rename to employee;
alter table employee rename to emp;


-- DML : 数据操作语言
-- 插入数据
-- 1.为emp表插入数据
insert into emp(username, password, name, gender, phone, job, salary, entry_date, image,create_time,update_time)
    values('Tom', '123456', '汤姆', 1, '13800000000',
           1, 5000, '2023-01-01', 'https://www.baidu.com',
           now(),now());

insert into emp(username, password, name, gender, phone, job, salary, entry_date, image,create_time,update_time)
    values('Rose', '123456', '罗斯', 2, '13800000001',
           2, 5000, '2023-01-02', 'https://www.baidu.com',
           now(),now());

-- 2.为emp表插入多条数据
insert into emp(username, password, name, gender, phone, job, salary, entry_date, image,create_time,update_time)
values
    ('Weili', '123456', '伟丽', 2, '13800000002',
       2, 5000, '2023-01-02', 'https://www.baidu.com',
       now(),now()),
    ('Conner', '123456', '康纳', 2, '13800000003',
       2, 8000, '2023-01-02', 'https://www.baidu.com',
       now(),now());
