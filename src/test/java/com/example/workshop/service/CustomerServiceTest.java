package com.example.workshop.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import com.example.workshop.domain.Customer;
import com.example.workshop.dto.CreateCustomerRequest;
import com.example.workshop.dto.CustomerResponse;
import com.example.workshop.repository.CustomerRepository;

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
