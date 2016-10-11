package com.mohe.springbootDemo.springDemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

// http://blog.csdn.net/xiaoyu411502/article/details/47864969
@SpringBootApplication
/*
 * Spring WebMvc框架会将Servlet容器里收到的HTTP请求 根据路径分发给对应的@Controller类进行处理，
 * 
 * @RestController是一类特殊的@Controller， 它的返回值直接作为HTTP Response的Body部分返回给浏览器。
 */
@RestController
public class Application {

	/*
	 * 
	 * @RequestMapping注解表明该方法处理那些URL对应的HTTP请求，
	 * 也就是我们常说的URL路由（routing)，请求的分发工作是有Spring完成的。
	 * 例如上面的代码中http://localhost:8080/根路径就被路由至greeting()方法进行处理
	 * 。如果访问http://localhost:8080/hello， 则会出现404 Not
	 * Found错误，因为我们并没有编写任何方法来处理/hello请求。
	 */
	@RequestMapping("/sayHello")
	public String greeting() {
		// 访问 http://localhost:8080/sayHello
		return "Hello dengbb!";
	}

	// 匹配多个URL
	@RequestMapping("/")
	public String greetingToWorld() {
		// 访问 http://localhost:8080
		return "Hello world!";
	}

	public static void main(String[] args) {
		/*
		 * SpringApplication是Spring Boot框架中描述Spring应用的类
		 * ，它的run()方法会创建一个Spring应用上下文（Application Context）。
		 * 另一方面它会扫描当前应用类路径上的依赖，例如本例中发现spring-webmvc（由
		 * spring-boot-starter-web传递引入）在类路径中，那么Spring Boot会判断这是一个Web应用，
		 * 并启动一个内嵌的Servlet容器（默认是Tomcat）用于处理HTTP请求。
		 */
		SpringApplication.run(Application.class, args);
	}

	/*
	 * @RequestMapping可以注解@Controller类：
	 * 
	 * @RestController
	 * 
	 * @RequestMapping("/classPath") public class Application {
	 * 
	 * @RequestMapping("/methodPath") public String method() { return
	 * "mapping url is /classPath/methodPath"; } }
	 * method方法匹配的URL是/classPath/methodPath"。
	 */

	/*
	 * 
	 * URL中的变量——PathVariable
	 * 
	 * 在Web应用中URL通常不是一成不变的，例如微博两个不同用 户的个人主页对应两个不同的URL: http://weibo.com/user1，
	 * http://weibo.com/user2。我们不可能对于每一个用户都编写一个被
	 * 
	 * @RequestMapping注解 的方法来处理其请求，Spring MVC提供了一套机制来处理这种情况：
	 * 
	 * http://localhost:8080/users/deng
	 */
	@RequestMapping("/users/{username}")
	public String userProfile(@PathVariable("username") String username) {
		return String.format("user %s", username);
	}

	@RequestMapping("/posts/{id}")
	public String post(@PathVariable("id") int id) {
		return String.format("post %d", id);
	}

	// 支持HTTP方法
	//
	// 对于HTTP请求除了其URL，还需要注意它的方法（Method）。例如我们在浏览器中访问一个页面通常是GET方法，而表单的提交一般是POST方法。@Controller中的方法同样需要对其进行区分：
	// http://localhost:8080/login
	@RequestMapping(value = "/login", method = RequestMethod.GET)
	public String loginGet() {
		return "Login Page";
	}

	@RequestMapping(value = "/login", method = RequestMethod.POST)
	public String loginPost() {
		return "Login Post Request";
	}

}
