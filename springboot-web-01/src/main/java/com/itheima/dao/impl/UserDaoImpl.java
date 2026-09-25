package com.itheima.dao.impl;

import cn.hutool.core.io.IoUtil;
import com.itheima.dao.UserDao;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Repository;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

@Repository  //数据层 Bean，交给 Spring 管理
// @Component
public class UserDaoImpl implements UserDao {

    @Override
    public List<String> findAll() {
        //从类路径(resource)读取文件
        InputStream in = this.getClass().getClassLoader().getResourceAsStream("user.txt");
        //Hutool工具(胡涂三连):一次性把流读成“每行
        List<String> lines = IoUtil.readLines(in, StandardCharsets.UTF_8,new ArrayList<>());

        return lines;
    }
}

/**
笔记：
 - 类名.class.getClassLoader().getResourceAsStream("文件名")`：读取 `resources` 下的资源，
        返回 `InputStream`（文件编译后在类路径根目录）
 - Hutool 是国产 Java 工具库，`IoUtil.readLines(流, 编码, 集合)` 一次读完所有行。pom 中引入
 */