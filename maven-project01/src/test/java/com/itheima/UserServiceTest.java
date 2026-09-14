package com.itheima;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

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
}
