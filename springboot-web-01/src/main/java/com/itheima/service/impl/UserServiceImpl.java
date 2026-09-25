package com.itheima.service.impl;

import com.itheima.dao.UserDao;
import com.itheima.pojo.User;
import com.itheima.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service //业务层
public class UserServiceImpl implements UserService {

    @Autowired //让 spring 把 userdao 的实现类对象注入进来(不用自己new)
    private UserDao userDao;

    @Override
    public List<User> findAll() {
        //1.调用Dao(数据层)的方法查询所有用户信息
        List<String> lines = userDao.findAll();

        //2.用 Stream 把每一行解析成 User 对象
        List<User> userList = lines.stream().map(line -> {
            String[] parts = line.split(",");
            Integer id = Integer.parseInt(parts[0]);
            String username = parts[1];
            String password = parts[2];
            String name = parts[3];
            Integer age = Integer.parseInt(parts[4]);
            LocalDateTime updateTime =
                    LocalDateTime.parse(parts[5], DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

            return new User(id, username, password, name, age, updateTime);
        }).toList();

        return userList;
    }
}