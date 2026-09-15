package com.itheima;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@RestController
public class HelloController {

    @RequestMapping("/hello")
    public String hello(@RequestParam String name) {
        System.out.println("访问请求参数 "+name); //后台控制台输出
        return "hello " + name; //参数返回给前端
    }
}
