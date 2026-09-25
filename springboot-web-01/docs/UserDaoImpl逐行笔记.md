
---

## 逐行讲解 UserDaoImpl类

**第 1 行 `package com.itheima.dao.impl;`**
声明这个类所在的包。注意包名结构本身就是分层的体现：`dao` 是数据访问层的包，`impl` 是它的子包，专门放**接口的实现类**。以后你看到 `xxx.impl`，基本就是这个套路：接口放上层包，实现放下面的 impl 包。

**第 3 行 `import cn.hutool.core.io.IoUtil;`**
导入 Hutool 工具库的 IO 工具类。Hutool 是个国产 Java 工具库，帮你把「读文件」这种繁琐操作封装成一行代码。没有它，你得自己写 BufferedReader 循环读、处理异常、关流——十几行。这个依赖是在 pom.xml 里引入的。

**第 4 行 `import com.itheima.dao.UserDao;`**
导入数据访问层的**接口**。注意：这个类不是自己单干，而是去实现这个接口——这就是解耦的关键伏笔，最后细说。

**第 5 行 `import org.springframework.stereotype.Repository;`**
导入 Spring 的 `@Repository` 注解。它是三大分层注解之一，专门给数据层用。

**第 7~10 行（java.io / nio / util 的导入）**
读文件需要的 `InputStream`（字节输入流）、指定 UTF-8 编码用的 `StandardCharsets`、以及装结果的 `ArrayList` 和 `List`。

**第 12 行 `@Repository`**
这一行是这个类的「灵魂」。

- 加上它之后，Spring Boot 启动时会扫描到这个类，**自动创建一个对象放进 IoC 容器**（Spring 管理的单例 Bean），以后谁要用，Spring 直接递过去。
- `@Repository` 本质是 `@Component` 的「语义版」：三个分层注解 `@Controller`（控制层）、`@Service`（业务层）、`@Repository`（数据层）功能上几乎一样，区别只在语义——看注解就知道这个 Bean 属于哪一层。**技术上换成 @Component 也能跑，但别这么干**，语义清晰是分层的纪律。

**第 13 行 `public class UserDaoImpl implements UserDao {`**
两个点：

1. 类名 `UserDaoImpl` = `UserDao` + `Impl`，这是 Java 圈约定俗成的命名：接口叫 UserDao，实现类就叫 UserDaoImpl。
2. `implements UserDao` 说明它必须兑现接口承诺的所有方法。这里接口只声明了一个 `findAll()`，所以它也只实现这一个。

**第 15 行 `@Override`**
告诉编译器：下面这个方法是在重写父接口里的方法。写它的好处是：如果你方法名拼错了（比如写成 `findAlll`），编译器会立刻报错，而不是留一个隐蔽的 bug 到运行时才炸。属于「零成本的安全带」。

**第 16 行 `public List<String> findAll() {`**
方法签名和接口里声明的一模一样：入参没有，返回 `List<String>`——每一行用户数据是字符串，整个用户表就是字符串列表。（真实项目里这里会返回 `List<User>`，是个实体类，教程为了让数据从文件来，先简化成了 String。）

**第 18 行 `InputStream in = this.getClass().getClassLoader().getResourceAsStream("user.txt");`**
这行是全文件最绕的，拆开读：

- `this.getClass()` → 拿到当前类 `UserDaoImpl` 的 Class 对象（类的「说明书」）。
- `.getClassLoader()` → 拿到类加载器。
- `.getResourceAsStream("user.txt")` → 去**类路径（classpath）**下找 `user.txt`，把文件变成字节输入流。

关键问题是「类路径在哪」：你项目里文件放在 `src/main/resources/user.txt`，但 Maven 编译后 resources 下的文件会被原样复制到 `target/classes/` 目录，**和 .class 文件待在一起**——这个 target/classes 就是类路径。所以不能写死 `D:\xxx\user.txt` 这种绝对路径，用类路径读，代码换台机器照样能跑。

**第 20 行 `List<String> lines = IoUtil.readLines(in, StandardCharsets.UTF_8, new ArrayList<>());`**
Hutool 的三连：把刚才的流 `in`，按 `UTF-8` 编码，逐行读完塞进 `new ArrayList<>()` 这个容器，最后返回它并交给 `lines` 接住。比如 user.txt 里有 3 行数据，lines 就是长度 3 的列表，一行一个元素。没有 Hutool 的话，这段等价于自己 new BufferedReader → while 循环 readLine → try-catch → finally 关流，五六十年代 Java 程序员就是这么过来的 😄

**第 22 行 `return lines;`**
把结果返回给调用者（后面会是 Service 层）。注意 DAO 层的职责到此为止——**只管取数据，不管加工**。数据怎么过滤、怎么拼业务逻辑，是 Service 层的事。

---

## 重点：它和「分层解耦」的关系

单独看这个类，你可能觉得「读个文件至于这么麻烦？」。把它放进三层架构里看：

```
Controller（接收请求） → Service（处理业务） → DAO（取数据） → user.txt
```

**解耦的核心就藏在第 4 行和第 12 行的组合里：**

1. Service 层的代码里写的**不是** `UserDaoImpl dao = new UserDaoImpl()`，而是声明 `UserDao` 这个**接口类型**。它只认识「有一个能 findAll 的东西」，不关心具体是文件读的、MySQL 读的还是 Redis 读的。

2. 这个类通过 `@Repository` 把自己的控制权交给 Spring——不是使用者 new 它，而是 Spring 创建它。哪天 Service 需要它了，Spring 把容器里这个 Bean 注入进去（这就是「控制反转 IoC + 依赖注入 DI」）。

3. 于是效果是：明天你要把数据源从 user.txt 换成 MySQL，只需新写一个 `UserDaoImplMysql implements UserDao` 也加上 `@Repository`，**Service 层一行代码都不用改**。如果当初 Service 里写死了 `new UserDaoImpl()`，那就要翻遍所有代码改 new——这就是「耦合」的代价。

一句话总结这个类：**数据层的接口实现 + @Repository 注入容器 + 只负责读文件返回原始数据**。接口定标准、实现干脏活、Spring 牵线——三层架构的地基就是这么垒的。