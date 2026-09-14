package com.itheima;

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
}
