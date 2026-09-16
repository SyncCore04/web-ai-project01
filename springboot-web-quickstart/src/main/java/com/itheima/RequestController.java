package com.itheima;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import java.io.IOException;
import java.util.stream.Collectors;

@RestController
public class RequestController {

    //访问链接: http://localhost:8080/request?name=tom&age=18
    @RequestMapping("/request")
    public String request(HttpServletRequest request) throws IOException {
        //1.获取请求方式
        String method = request.getMethod();
        System.out.println("请求方式 "+method);

        //2.获取请求url路径
        String requestURI = request.getRequestURI();
        System.out.println("请求资源访问uri路径 "+requestURI);

        String requestURL = String.valueOf(request.getRequestURL());
        System.out.println("完整url路径 "+requestURL);

        //3.获取请求协议
        String protocol = request.getProtocol();
        System.out.println("请求协议 "+protocol);

        //4.获取请求参数
        String name = request.getParameter("name");
        String age = request.getParameter("age");
        System.out.println("请求参数 name "+name);
        System.out.println("请求参数 age "+age);

        //5.获取请求头
        String accept = request.getHeader("Accept");
        System.out.println("请求头 Accept "+accept);

        //6.获取请求体
        String requestBody = request.getReader().lines().collect(Collectors.joining());
        System.out.println("请求体 "+requestBody);

        //int n=1/0;//返回500报错
        return "OK";
    }
}
