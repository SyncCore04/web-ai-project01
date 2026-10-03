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

-- update 更新数据
-- 1.将 emp 表中 id 为 1 的员工薪资更新为 6000
update emp set salary = 6000 where id = 1 and job = 1;

-- 1.将 emp 表所有的入职日期改为"2025-01-01"
update emp set entry_date = '2025-01-01';


-- delete 删除数据
-- 0.增加一个临时员工
insert into emp(username, password, name, gender, phone, job, salary, entry_date, image,create_time,update_time)
    values('Temp', '123456', '临时员工', 2, '13800000004',
           2, 5000, '2023-01-02', 'https://www.baidu.com',
           now(),now());

-- 1.删除 emp 表中 id 为 6 的员工(临时员工)
delete from  emp where  id = 6;

-- 2.清空整个表
delete from emp;


-- DQL
-- 基本查询
-- 准备测试数据
INSERT INTO emp(id, username, password, name, gender, phone, job, salary, image, entry_date, create_time, update_time)
VALUES (1,'shinaian','123456','施耐庵',1,'13309090001',4,15000,'1.jpg','2000-01-01','2024-04-11 16:35:33','2024-04-11 16:35:35'),
       (2,'songjiang','123456','宋江',1,'13309090002',2,8600,'2.jpg','2015-01-01','2024-04-11 16:35:33','2024-04-11 16:35:37'),
       (3,'lujunyi','123456','卢俊义',1,'13309090003',2,8900,'3.jpg','2008-05-01','2024-04-11 16:35:33','2024-04-11 16:35:39'),
       (4,'wuyong','123456','吴用',1,'13309090004',2,9200,'4.jpg','2007-01-01','2024-04-11 16:35:33','2024-04-11 16:35:41'),
       (5,'gongsunsheng','123456','公孙胜',1,'13309090005',2,9500,'5.jpg','2012-12-05','2024-04-11 16:35:33','2024-04-11 16:35:43'),
       (6,'huosanniang','123456','扈三娘',2,'13309090006',3,6500,'6.jpg','2013-09-05','2024-04-11 16:35:33','2024-04-11 16:35:45'),
       (7,'chaijin','123456','柴进',1,'13309090007',1,4700,'7.jpg','2005-08-01','2024-04-11 16:35:33','2024-04-11 16:35:47'),
       (8,'likui','123456','李逵',1,'13309090008',1,4800,'8.jpg','2014-11-09','2024-04-11 16:35:33','2024-04-11 16:35:49'),
       (9,'wusong','123456','武松',1,'13309090009',1,4900,'9.jpg','2011-03-11','2024-04-11 16:35:33','2024-04-11 16:35:51'),
       (10,'lichong','123456','林冲',1,'13309090010',1,5000,'10.jpg','2013-09-05','2024-04-11 16:35:33','2024-04-11 16:35:53'),
       (11,'huyanzhuo','123456','呼延灼',1,'13309090011',2,9700,'11.jpg','2007-02-01','2024-04-11 16:35:33','2024-04-11 16:35:55'),
       (12,'xiaoliguang','123456','小李广',1,'13309090012',2,10000,'12.jpg','2008-08-18','2024-04-11 16:35:33','2024-04-11 16:35:57'),
       (13,'yangzhi','123456','杨志',1,'13309090013',1,5300,'13.jpg','2012-11-01','2024-04-11 16:35:33','2024-04-11 16:35:59'),
       (14,'shijin','123456','史进',1,'13309090014',2,10600,'14.jpg','2002-08-01','2024-04-11 16:35:33','2024-04-11 16:36:01'),
       (15,'sunerniang','123456','孙二娘',2,'13309090015',2,10900,'15.jpg','2011-05-01','2024-04-11 16:35:33','2024-04-11 16:36:03'),
       (16,'luzhishen','123456','鲁智深',1,'13309090016',2,9600,'16.jpg','2010-01-01','2024-04-11 16:35:33','2024-04-11 16:36:05'),
       (17,'liying','12345678','李应',1,'13309090017',1,5800,'17.jpg','2015-03-21','2024-04-11 16:35:33','2024-04-11 16:36:07'),
       (18,'shiqian','123456','时迁',1,'13309090018',2,10200,'18.jpg','2015-01-01','2024-04-11 16:35:33','2024-04-11 16:36:09'),
       (19,'gudasao','123456','顾大嫂',2,'13309090019',2,10500,'19.jpg','2008-01-01','2024-04-11 16:35:33','2024-04-11 16:36:11'),
       (20,'ruanxiaoer','123456','阮小二',1,'13309090020',2,10800,'20.jpg','2018-01-01','2024-04-11 16:35:33','2024-04-11 16:36:13'),
       (21,'ruanxiaowu','123456','阮小五',1,'13309090021',5,5200,'21.jpg','2015-01-01','2024-04-11 16:35:33','2024-04-11 16:36:15'),
       (22,'ruanxiaoqi','123456','阮小七',1,'13309090022',5,5500,'22.jpg','2016-01-01','2024-04-11 16:35:33','2024-04-11 16:36:17'),
       (23,'ruanji','123456','阮籍',1,'13309090023',5,5800,'23.jpg','2012-01-01','2024-04-11 16:35:33','2024-04-11 16:36:19'),
       (24,'tongwei','123456','童威',1,'13309090024',5,5000,'24.jpg','2006-01-01','2024-04-11 16:35:33','2024-04-11 16:36:21'),
       (25,'tongmeng','123456','童猛',1,'13309090025',5,4800,'25.jpg','2002-01-01','2024-04-11 16:35:33','2024-04-11 16:36:23'),
       (26,'yanshun','123456','燕顺',1,'13309090026',5,5400,'26.jpg','2011-01-01','2024-04-11 16:35:33','2024-04-11 16:36:25'),
       (27,'lijun','123456','李俊',1,'13309090027',5,6600,'27.jpg','2004-01-01','2024-04-11 16:35:33','2024-04-11 16:36:27'),
       (28,'lizhong','123456','李忠',1,'13309090028',5,5000,'28.jpg','2007-01-01','2024-04-11 16:35:33','2024-04-11 16:36:29'),
       (29,'songqing','123456','宋清',1,'13309090029',5,5100,'29.jpg','2020-01-01','2024-04-11 16:35:33','2024-04-11 16:36:31'),
       (30,'liyun','123456','李云',1,'13309090030',NULL,NULL,'30.jpg','2020-03-01','2024-04-11 16:35:33','2024-04-11 16:36:31');


--  =================== DQL: 基本查询 ======================
-- 1. 查询指定字段 name,entry_date 并返回
select name,entry_date from emp;

-- 2. 查询返回所有字段
select * from emp;
-- 注意：* 表示查询所有字段，建议在生产环境中避免使用 *，因为会返回所有字段，包括密码等敏感信息。

-- 3. 查询所有员工的 name,entry_date, 并起别名(姓名、入职日期)
 select name as 姓名,entry_date as 入职日期 from emp;

-- 4. 查询已有的员工关联了哪几种职位(不要重复) - distinct
select distinct job from emp;

--  =================== DQL: 条件查询 ======================
-- 1. 查询 姓名 为 柴进 的员工
SELECT * FROM emp WHERE name = '柴进';

-- 2. 查询 薪资小于等于5000 的员工信息
SELECT * FROM emp WHERE salary <= 5000;

-- 3. 查询 没有分配职位 的员工信息
SELECT * FROM emp WHERE job IS NULL;

-- 4. 查询 有职位 的员工信息
SELECT * FROM emp WHERE job IS NOT NULL;

-- 5. 查询 密码不等于 '123456' 的员工信息
SELECT * FROM emp WHERE password <> '123456';

-- 6. 查询 入职日期 在 '2000-01-01' (包含) 到 '2010-01-01'(包含) 之间的员工信息
SELECT * FROM emp WHERE entry_date BETWEEN '2000-01-01' AND '2010-01-01';

-- 7. 查询 入职时间 在 '2000-01-01' (包含) 到 '2010-01-01'(包含) 之间 且 性别为女 的员工信息
SELECT * FROM emp WHERE entry_date BETWEEN '2000-01-01' AND '2010-01-01' AND gender = 2;

-- 8. 查询 职位是 2 (讲师), 3 (学工主管), 4 (教研主管) 的员工信息
SELECT * FROM emp WHERE job IN (2, 3, 4);

-- 9. 查询 姓名 为两个字的员工信息
SELECT * FROM emp WHERE CHAR_LENGTH(name) = 2;

-- 10. 查询 姓 '李' 的员工信息
SELECT * FROM emp WHERE name LIKE '李%';

-- 11. 查询 姓名中包含 '二' 的员工信息
SELECT * FROM emp WHERE name LIKE '%二%';
