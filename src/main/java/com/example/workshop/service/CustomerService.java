package com.example.workshop.service;

import java.util.List;

import com.example.workshop.domain.Customer;
import com.example.workshop.dto.CreateCustomerRequest;
import com.example.workshop.dto.CustomerResponse;
import com.example.workshop.repository.CustomerRepository;

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
