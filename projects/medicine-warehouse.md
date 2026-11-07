# Medicine Warehouse Management

**A modular Java application for medicine records, stock information, and employee management.**

[Portfolio](../README.md) · [Coursework](coursework.md)

## Purpose

The project organizes warehouse-related information into medicine, employee, and shared application modules. It explores how a business application can separate domain logic while exposing functionality through a web interface.

## Modules in the reviewed build

| Module | Responsibility |
| --- | --- |
| `gateway-service` | Gateway component for the service architecture |
| `medicine-service` | Medicine, category, and stock-related functionality |
| `employee-service` | Employee-related functionality |
| `common-service` | Shared components |
| `medicine-web` | Web interface with medicine, category, and stock views |

The parent Maven build declares the first four modules. A separate inventory-service entry is commented out, so the available stock functionality is described through the medicine-related modules.

## Features visible in source

The reviewed controllers include authentication, employees, medicine categories, medicine records, and medicine stock. Frontend views correspond to medicine, category, and stock screens.

These components provide material for studying a gateway-based application layout, relational business records, and the boundaries between shared and domain-specific code.

## Technology stack

The parent build declares Java 8, Spring Boot 2.7.18, Spring Cloud 2021.0.5, Spring Cloud Alibaba 2021.0.4.0, MyBatis-Plus 3.5.2, and a MySQL connector. These versions describe the existing project configuration.

## Available materials and status

Local source and documentation have been located. This public page is a project overview, while a sanitized source release and environment setup are pending.

The service stack has not been started and validated end to end for this portfolio. The architecture description reflects the reviewed modules rather than a claim of production deployment.

## Planned improvements

- Document service startup order and external dependencies.
- Define and test stock update behavior, including concurrent operations.
- Add a small synthetic dataset and example configuration.
- Record a demo covering medicine creation, stock changes, and employee access.
