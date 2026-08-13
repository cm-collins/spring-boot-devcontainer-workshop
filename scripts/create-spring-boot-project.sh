#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${APP_NAME:-workshop-app}"
GROUP_ID="${GROUP_ID:-com.example}"
ARTIFACT_ID="${ARTIFACT_ID:-workshop-app}"
PACKAGE_NAME="${PACKAGE_NAME:-com.example.workshop}"
JAVA_VERSION="${JAVA_VERSION:-21}"
DEPENDENCIES="${DEPENDENCIES:-web,data-jpa,postgresql,actuator,validation,devtools}"

if [ -f "$REPO_ROOT/pom.xml" ] || [ -d "$REPO_ROOT/src" ]; then
    echo "A Spring Boot project already exists in this repository."
    echo "Remove pom.xml and src/ first if you intentionally want to generate a fresh project."
    exit 1
fi

for command in curl unzip; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "ERROR: $command is required to generate the Spring Boot project."
        exit 1
    fi
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

starter_zip="$tmp_dir/starter.zip"
generated_dir="$tmp_dir/generated"

echo "Downloading Spring Boot project from Spring Initializr..."
curl -fsSL "https://start.spring.io/starter.zip" \
    --get \
    --data-urlencode "type=maven-project" \
    --data-urlencode "language=java" \
    --data-urlencode "baseDir=generated" \
    --data-urlencode "groupId=$GROUP_ID" \
    --data-urlencode "artifactId=$ARTIFACT_ID" \
    --data-urlencode "name=$APP_NAME" \
    --data-urlencode "description=Spring Boot application for the Dev Container workshop" \
    --data-urlencode "packageName=$PACKAGE_NAME" \
    --data-urlencode "packaging=jar" \
    --data-urlencode "javaVersion=$JAVA_VERSION" \
    --data-urlencode "dependencies=$DEPENDENCIES" \
    -o "$starter_zip"

echo "Extracting project..."
unzip -q "$starter_zip" -d "$tmp_dir"

cp -a "$generated_dir/.mvn" "$REPO_ROOT/"
cp -a "$generated_dir/mvnw" "$REPO_ROOT/"
cp -a "$generated_dir/mvnw.cmd" "$REPO_ROOT/"
cp -a "$generated_dir/pom.xml" "$REPO_ROOT/"
cp -a "$generated_dir/src" "$REPO_ROOT/"

if [ -f "$generated_dir/.gitignore" ] && [ ! -f "$REPO_ROOT/.gitignore" ]; then
    cp -a "$generated_dir/.gitignore" "$REPO_ROOT/"
fi

chmod +x "$REPO_ROOT/mvnw"

package_path="${PACKAGE_NAME//.//}"
main_source_dir="$REPO_ROOT/src/main/java/$package_path"
resources_dir="$REPO_ROOT/src/main/resources"
test_source_dir="$REPO_ROOT/src/test/java/$package_path"
test_resources_dir="$REPO_ROOT/src/test/resources"

mkdir -p "$main_source_dir" "$resources_dir"
mkdir -p \
    "$main_source_dir/controller" \
    "$main_source_dir/domain" \
    "$main_source_dir/dto" \
    "$main_source_dir/repository" \
    "$main_source_dir/service"
mkdir -p "$test_source_dir/service" "$test_resources_dir"

sed -i '/<\/dependencies>/i\
		<dependency>\
			<groupId>com.h2database</groupId>\
			<artifactId>h2</artifactId>\
			<scope>test</scope>\
		</dependency>' "$REPO_ROOT/pom.xml"

cat > "$resources_dir/application.properties" <<'PROPERTIES'
spring.application.name=workshop-app

server.port=${SERVER_PORT:8080}

spring.datasource.url=${SPRING_DATASOURCE_URL:jdbc:postgresql://postgres:5432/spring_boot_dev}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME:spring_boot}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD:spring_boot_dev_password}

spring.jpa.hibernate.ddl-auto=update
spring.jpa.open-in-view=false

management.endpoints.web.exposure.include=health,info
PROPERTIES

sed -i "s/^spring.application.name=.*/spring.application.name=$APP_NAME/" "$resources_dir/application.properties"

cat > "$test_resources_dir/application-test.properties" <<'PROPERTIES'
spring.datasource.url=jdbc:h2:mem:workshop_test;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH
spring.datasource.username=sa
spring.datasource.password=

spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.open-in-view=false
PROPERTIES

cat > "$main_source_dir/controller/WelcomeController.java" <<JAVA
package $PACKAGE_NAME.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class WelcomeController {

    @GetMapping("/hello")
    public Map<String, String> hello() {
        return Map.of(
            "message", "Spring Boot is running inside the Dev Container",
            "database", "PostgreSQL is configured through environment variables"
        );
    }
}
JAVA

cat > "$main_source_dir/controller/CustomerController.java" <<JAVA
package $PACKAGE_NAME.controller;

import java.net.URI;
import java.util.List;

import $PACKAGE_NAME.dto.CreateCustomerRequest;
import $PACKAGE_NAME.dto.CustomerResponse;
import $PACKAGE_NAME.service.CustomerService;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/customers")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @GetMapping
    public List<CustomerResponse> listCustomers() {
        return customerService.listCustomers();
    }

    @GetMapping("/{id}")
    public CustomerResponse getCustomer(@PathVariable Long id) {
        return customerService.getCustomer(id);
    }

    @PostMapping
    public ResponseEntity<CustomerResponse> createCustomer(@Valid @RequestBody CreateCustomerRequest request) {
        CustomerResponse customer = customerService.createCustomer(request);
        return ResponseEntity
            .created(URI.create("/api/customers/" + customer.id()))
            .body(customer);
    }
}
JAVA

cat > "$main_source_dir/domain/Customer.java" <<JAVA
package $PACKAGE_NAME.domain;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "customers")
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    protected Customer() {
    }

    public Customer(String name, String email) {
        this.name = name;
        this.email = email;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
JAVA

cat > "$main_source_dir/dto/CreateCustomerRequest.java" <<JAVA
package $PACKAGE_NAME.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record CreateCustomerRequest(
    @NotBlank String name,
    @Email @NotBlank String email
) {
}
JAVA

cat > "$main_source_dir/dto/CustomerResponse.java" <<JAVA
package $PACKAGE_NAME.dto;

import java.time.Instant;

public record CustomerResponse(
    Long id,
    String name,
    String email,
    Instant createdAt
) {
}
JAVA

cat > "$main_source_dir/repository/CustomerRepository.java" <<JAVA
package $PACKAGE_NAME.repository;

import $PACKAGE_NAME.domain.Customer;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CustomerRepository extends JpaRepository<Customer, Long> {
}
JAVA

cat > "$main_source_dir/service/CustomerService.java" <<JAVA
package $PACKAGE_NAME.service;

import java.util.List;

import $PACKAGE_NAME.domain.Customer;
import $PACKAGE_NAME.dto.CreateCustomerRequest;
import $PACKAGE_NAME.dto.CustomerResponse;
import $PACKAGE_NAME.repository.CustomerRepository;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class CustomerService {

    private final CustomerRepository customerRepository;

    public CustomerService(CustomerRepository customerRepository) {
        this.customerRepository = customerRepository;
    }

    @Transactional(readOnly = true)
    public List<CustomerResponse> listCustomers() {
        return customerRepository.findAll()
            .stream()
            .map(this::toResponse)
            .toList();
    }

    @Transactional(readOnly = true)
    public CustomerResponse getCustomer(Long id) {
        return customerRepository.findById(id)
            .map(this::toResponse)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));
    }

    @Transactional
    public CustomerResponse createCustomer(CreateCustomerRequest request) {
        Customer customer = new Customer(request.name(), request.email());
        return toResponse(customerRepository.save(customer));
    }

    private CustomerResponse toResponse(Customer customer) {
        return new CustomerResponse(
            customer.getId(),
            customer.getName(),
            customer.getEmail(),
            customer.getCreatedAt()
        );
    }
}
JAVA

application_test_file="$(find "$test_source_dir" -name '*ApplicationTests.java' -print -quit)"
if [ -n "$application_test_file" ]; then
    if ! grep -q 'ActiveProfiles' "$application_test_file"; then
        sed -i '/import org.springframework.boot.test.context.SpringBootTest;/a import org.springframework.test.context.ActiveProfiles;' "$application_test_file"
        sed -i '/@SpringBootTest/a @ActiveProfiles("test")' "$application_test_file"
    fi
fi

cat > "$test_source_dir/service/CustomerServiceTest.java" <<JAVA
package $PACKAGE_NAME.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import $PACKAGE_NAME.domain.Customer;
import $PACKAGE_NAME.dto.CreateCustomerRequest;
import $PACKAGE_NAME.dto.CustomerResponse;
import $PACKAGE_NAME.repository.CustomerRepository;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {

    @Mock
    private CustomerRepository customerRepository;

    @InjectMocks
    private CustomerService customerService;

    @Test
    void listCustomersReturnsRepositoryResults() {
        when(customerRepository.findAll())
            .thenReturn(List.of(new Customer("Ada Lovelace", "ada@example.com")));

        List<CustomerResponse> customers = customerService.listCustomers();

        assertThat(customers).hasSize(1);
        assertThat(customers.getFirst().name()).isEqualTo("Ada Lovelace");
        assertThat(customers.getFirst().email()).isEqualTo("ada@example.com");
    }

    @Test
    void getCustomerThrowsNotFoundWhenMissing() {
        when(customerRepository.findById(42L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> customerService.getCustomer(42L))
            .isInstanceOf(ResponseStatusException.class)
            .hasMessageContaining("Customer not found");
    }

    @Test
    void createCustomerSavesNewCustomer() {
        when(customerRepository.save(any(Customer.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        CustomerResponse customer = customerService.createCustomer(
            new CreateCustomerRequest("Grace Hopper", "grace@example.com")
        );

        assertThat(customer.name()).isEqualTo("Grace Hopper");
        assertThat(customer.email()).isEqualTo("grace@example.com");
    }
}
JAVA

echo
echo "Spring Boot project created."
echo
echo "Generated:"
echo "- pom.xml"
echo "- Maven wrapper"
echo "- src/main/java/$package_path/controller"
echo "- src/main/java/$package_path/service"
echo "- src/main/java/$package_path/repository"
echo "- src/main/java/$package_path/domain"
echo "- src/main/java/$package_path/dto"
echo "- src/main/resources/application.properties"
echo "- src/test/resources/application-test.properties"
echo "- src/test/java/$package_path/service/CustomerServiceTest.java"
echo
echo "Next commands:"
echo "bash scripts/run-spring-boot-app.sh"
echo "./mvnw test"
echo "curl http://localhost:8080/api/hello"
echo "curl http://localhost:8080/api/customers"
echo "curl http://localhost:8080/actuator/health"
