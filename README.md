# Odoo Sales App

A Flutter mobile application integrated with Odoo ERP for managing customers and sales orders.

## Overview

Odoo Sales App is an MVP Flutter application that connects directly to an Odoo instance using XML-RPC APIs.

The application provides:

- User authentication
- Customer management
- Customer search
- Customer details
- Customer phone number updates
- Sales order management for internal users
- Sales order details
- Sales order confirmation
- Offline customer caching
- Offline customer phone updates with automatic synchronization

## Features

### Authentication

- Login using Odoo credentials
- Authenticate against the Odoo database
- Detect internal users
- Show role-specific features

### Customers

- Fetch customers from `res.partner`
- Display:
  - Name
  - Phone
  - City
- Search customers by name
- View customer details
- Edit customer phone number

### Sales Orders

Available for internal Odoo users.

- List sales orders
- Display:
  - Order number
  - Customer
  - Order date
  - Status
- View order details
- Display products and quantities
- Display:
  - Untaxed amount
  - Tax
  - Total
- Confirm draft quotations

### Offline Support

The application supports offline customer access.

When offline:

- Cached customers remain available
- Customer search works using cached data
- Customer details can be viewed
- Phone number changes are stored locally
- Pending updates are queued for synchronization

When connectivity is restored:

```text
Offline
   ↓
Edit Customer
   ↓
Local Cache
   ↓
Pending Update Queue
   ↓
Internet Restored
   ↓
Sync with Odoo
   ↓
Update Successfully
