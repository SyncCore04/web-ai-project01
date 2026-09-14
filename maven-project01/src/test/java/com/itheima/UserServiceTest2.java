package com.itheima;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

public class UserServiceTest2 {

    /**
     * 依据指定出生日期拼接一个合法的18位身份证号：6位地区码 + 8位出生日期 + 4位顺序码
     */
    private static String buildIdCard(LocalDate birthday) {
        return "110000" + birthday.format(DateTimeFormatter.ofPattern("yyyyMMdd")) + "0111";
    }

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

    @Test
    @DisplayName("getAge - null 应抛出异常")
    public void testGetAgeNull() {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getAge(null);
        });
    }

    @Test
    @DisplayName("getAge - 空字符串应抛出异常")
    public void testGetAgeEmpty() {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getAge("");
        });
    }

    @Test
    @DisplayName("getAge - 长度不足应抛出异常")
    public void testGetAgeShort() {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getAge("110");
        });
    }

    @Test
    @DisplayName("getAge - 长度超限应抛出异常")
    public void testGetAgeLong() {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getAge("110000200010011110000");
        });
    }

    @Test
    @DisplayName("getAge - 正常身份证号应返回对应年龄")
    public void testGetAgeNormal() {
        UserService userService = new UserService();
        String idCard = buildIdCard(LocalDate.now().minusYears(25));
        Integer age = userService.getAge(idCard);
        Assertions.assertEquals(25, age);
    }

    @Test
    @DisplayName("getAge - 今年生日已过应按已满周岁计算")
    public void testGetAgeBirthdayPassed() {
        UserService userService = new UserService();
        String idCard = buildIdCard(LocalDate.now().minusYears(25).minusDays(1));
        Integer age = userService.getAge(idCard);
        Assertions.assertEquals(25, age);
    }

    @Test
    @DisplayName("getAge - 今年生日未到应少算一岁")
    public void testGetAgeBirthdayNotReached() {
        UserService userService = new UserService();
        String idCard = buildIdCard(LocalDate.now().minusYears(25).plusDays(1));
        Integer age = userService.getAge(idCard);
        Assertions.assertEquals(24, age);
    }

    @Test
    @DisplayName("getAge - 出生日期非法应抛出日期解析异常")
    public void testGetAgeInvalidBirthday() {
        UserService userService = new UserService();
        Assertions.assertThrows(DateTimeParseException.class, () -> {
            userService.getAge("110000200013010011");
        });
    }

    @DisplayName("getAge - 批量异常场景参数化测试")
    @ParameterizedTest
    @ValueSource(strings = {"", "110", "110000200010011110000"})
    public void testGetAgeInvalid(String idCard) {
        UserService userService = new UserService();
        Assertions.assertThrows(IllegalArgumentException.class, () -> {
            userService.getAge(idCard);
        });
    }

}