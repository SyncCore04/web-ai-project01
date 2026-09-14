package com.itheima;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

public class UserServiceTest2 {

    @Test
    @DisplayName("getGender - null 应抛出异常")
    public void testGetGenderNull() {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getGender(null);
        });
    }

    @Test
    @DisplayName("getGender - 空字符串应抛出异常")
    public void testGetGenderEmpty() {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getGender("");
        });
    }

    @Test
    @DisplayName("getGender - 长度不足应抛出异常")
    public void testGetGenderShort() {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getGender("110");
        });
    }

    @Test
    @DisplayName("getGender - 长度超限应抛出异常")
    public void testGetGenderLong() {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getGender("110000200010011110000");
        });
    }

    @Test
    @DisplayName("getGender - 第17位为奇数应返回男")
    public void testGetGenderMale() {
        UserService userService = new UserService();
        String gender = userService.getGender("110000200010010011");
        Assertions.assertEquals("男", gender);
    }

    @Test
    @DisplayName("getGender - 第17位为偶数应返回女")
    public void testGetGenderFemale() {
        UserService userService = new UserService();
        String gender = userService.getGender("110000200010010021");
        Assertions.assertEquals("女", gender);
    }

    @DisplayName("getGender - 批量异常场景参数化测试")
    @ParameterizedTest
    @ValueSource(strings = {"", "110", "110000200010011110000"})
    public void testGetGenderInvalid(String idCard) {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getGender(idCard);
        });
    }
}