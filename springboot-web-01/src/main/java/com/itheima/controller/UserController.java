package com.itheima.controller;

import com.itheima.pojo.User;
import com.itheima.service.UserService;
import jakarta.annotation.Resource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class UserController {
    // 方式一：属性注入
    //@Autowired
    //private UserService userService;

    // 方式二：构造方法注入
//    private final UserService userService;
//
//    //@Autowired
//    //如果当前类中，只存在一个构造方法，那么该注解可省略
//    public UserController(UserService userService) {
//        this.userService = userService;
//    }



    // 方式三：set 方法注入
    @Resource(name = "userService")
    private UserService userService;

    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }

    public UserService getUserService() {
        return userService;
    }

    public void setUserService(UserService userService) {
        this.userService = userService;
    }


    @RequestMapping("/list")
    public List<User> list() throws Exception {
        List<User> userList = userService.findAll();
        // @RestController 会把 List<User> 自动转换成 JSON 数组返回
        return userList;
    }

}