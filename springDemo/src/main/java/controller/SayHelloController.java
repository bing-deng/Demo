package controller;

import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/classPath")
public class SayHelloController {

	@RequestMapping("/users/{username}")
	public String userProfile(@PathVariable("username") String username) {
	    return String.format("user %s", username);
	}

	@RequestMapping("/posts/{id}")
	public String post(@PathVariable("id") int id) {
	    return String.format("post %d", id);
	}
}
