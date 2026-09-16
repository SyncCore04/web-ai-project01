package com.itheima;


import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;

@RestController
public class ResponseController {

    @RequestMapping("/response")
    public void response(HttpServletResponse response) throws IOException {
        //1.设置响应状态码
        //response.setStatus(HttpServletResponse.SC_OK);
        response.setStatus(401); //通常不设置状态码，默认是200
        // 2.设置响应头
        response.setHeader("name","itheima");
        // 3.设置响应体
        response.getWriter().write("<h1>hello itheima</h1>");
    }
}

