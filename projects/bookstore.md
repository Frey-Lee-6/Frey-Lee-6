# Online Bookstore

**A Java web course project covering browsing, shopping carts, orders, and administration.**

[Portfolio](../README.md) · [Coursework](coursework.md)

## Purpose

The application models the path from browsing books to creating an order. Customer-facing functionality is accompanied by administrative components for managing books, users, and orders.

## Main workflows

| Workflow | Supporting components |
| --- | --- |
| Access the application | Login controller and account-related application logic |
| Browse books | Book controller and paginated result representation |
| Manage a cart | Cart controller and quantity-oriented shopping flow |
| Review orders | Customer order controller |
| Administer the catalog | Administrative book, user, and order controllers |

The project README also describes client-side form validation and registration behavior. Those descriptions are retained as project context, while a fresh end-to-end verification is pending.

## Implementation

The local project describes an SSM stack, combining Spring, Spring MVC, and MyBatis with MySQL and Ajax-based page interactions. Its directory structure contains controller, service, and utility code, plus web resources.

The application illustrates the relationship between catalog entities, customer actions, and order records. Separate customer and administrative controllers make the major application areas easy to identify.

## Technical details worth exploring

- Pagination of book records.
- Session-related login and logout handling.
- Cart operations and order retrieval.
- Shared result and pagination representations.
- Administrative CRUD operations across books, users, and orders.

## Available materials and status

Local materials include the source tree, a README, a feature document, and a project description. The current public deliverable is this case study. Source publication, database preparation, and a clean deployment walkthrough are pending.

## Planned improvements

- Prepare synthetic book and customer data for demonstrations.
- Verify cart totals and order creation with focused tests.
- Document authorization for administrative operations.
- Publish screenshots from a verified local run.
