package com.itheima;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

public class UserServiceTest {
    @Test
    public void testGetAge() {
        UserService userService = new UserService();
        int age = userService.getAge("10000020010206002X");
        System.out.println(age);
    }

    @Test
    public void testGetGender() {
        UserService userService = new UserService();
        String gender = userService.getGender("10000020010206002X");
        System.out.println(gender);
    }

    /*
    断言 Assert
     */
    @Test
    public void testGetGenderAssert() {
        UserService userService = new UserService();
        String gender = userService.getGender("10000020010206002X");
        Assertions.assertEquals("女", gender, "性别断言失败");
    }

    /*
     测试性别断言失败，出现空指针异常
     */
    @Test
    public void testGetGenderAssert2() {
        UserService userService = new UserService();
        String gender = userService.getGender("10000020010206002X");
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
                userService.getGender(null);
        });
    }

    /*
    参数化测试
    批量测试
     */
    @ParameterizedTest
    @ValueSource(strings = {"100000200010011011", "100000200010011031", "100000200010011051"})
    public void testGetGender2(String idCard){
        UserService userService = new UserService();
        String gender = userService.getGender(idCard);
        //断言
        Assertions.assertEquals("男", gender);
    }

}
