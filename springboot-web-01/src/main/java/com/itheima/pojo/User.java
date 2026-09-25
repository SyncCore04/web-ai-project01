package com.itheima.pojo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data   //自动生成get/set方法
@NoArgsConstructor //自动生成无参构造
@AllArgsConstructor //自动生成有参构造

public class User {

    // 封装用户信息
    private Integer id;
    private String username;
    private String password;
    private String name;
    private Integer age;
    private LocalDateTime createTime;

}
