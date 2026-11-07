# Online Examination System

**A course application for organizing questions, exam papers, student submissions, and scores.**

[Portfolio](../README.md) · [Coursework](coursework.md)

## Purpose

The system brings exam preparation and student assessment into one web workflow. The reviewed local project contains a Spring Boot backend and a Vue interface, with separate controller areas for students, teachers, and administrators.

## Functional areas

| Area | Modules visible in the project |
| --- | --- |
| Accounts | Login, student, teacher, and administrator controllers |
| Question bank | Multiple-choice, fill-in-the-blank, and true/false question controllers |
| Assessment | Exam management, paper management, answers, and scores |
| Communication | Message and reply controllers |
| Presentation | Vue pages and chart components for score-related views |

The source structure supports examining the connection between question data, paper organization, submitted answers, and score records.

## Technical stack

The local README specifies Java 8 or later, Maven, MySQL, Spring Boot, and MyBatis-Plus for the backend. The frontend uses Vue 2, Element UI, Axios, and ECharts.

The application is organized as a browser client consuming a Java backend. The backend separates its controllers by business area, while the frontend includes chart components for presenting assessment information.

## Engineering focus

The project provides an example of modeling several question types within one assessment system, organizing role-specific application areas, and presenting results through a web interface.

## Available materials and status

Local materials include backend and frontend source, project instructions, and a database file. This page documents the project. A sanitized source release, demonstration dataset, and verified setup sequence are pending.

The listed modules come from source inspection. A complete exam submission and scoring flow has not been rerun for this portfolio.

## Planned improvements

- Document the relationship between questions, papers, answers, and scores.
- Add reproducible tests for scoring and duplicate submission handling.
- Demonstrate access rules for student, teacher, and administrator actions.
- Prepare synthetic accounts and exam content for a clean local demo.
