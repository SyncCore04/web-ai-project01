package com.itheima;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


@SpringBootApplication
public class SpringbootWeb01Application {

    public static void main(String[] args) {
        SpringApplication.run(SpringbootWeb01Application.class, args);
        System.out.println("项目启动成功！！！");
        System.out.println("静态网页地址: http://localhost:8080/user.html");
    }

}
