package com.cysvet.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class CysvetApplication {

    public static void main(String[] args) {
        SpringApplication.run(CysvetApplication.class, args);
    }
}
