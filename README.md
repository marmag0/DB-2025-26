# DB-2025-26

## Welcome to our project!
---

### Topic and Purpose 📚

This project is part of the Cybersecurity Engineering Degree Curriculum at AGH University of Science and Technology (AGH UST).
Its goal is to design and implement a **relational database for a general-purpose e-commerce store**.

The database will be developed with a strong focus on **data integrity**, **security**, and **scalability**, while following the **highest practical level of normalization standards** to ensure both efficiency and usability.

### Innovative Approach 💡

To make this project stand out, it leverages [TimescaleDB](https://www.tigerdata.com/blog/postgresql-timescaledb-1000x-faster-queries-90-data-compression-and-much-more) — an open-source time-series database that extends the core functionality of `PostgreSQL`.
By integrating TimescaleDB, the system ensures **high scalability**, **efficient handling of time-series data**, and **real-time statistical performance** for fast and reliable data processing.

### Migration Tool - Dbmate ♻️

Due to technical circumstances, the project will be developed on-premises, which creates a need to manage database migrations and synchronize changes across independent devices.
To address this, we use `Dbmate`, a **lightweight** and **accessible** migration tool that simplifies version control of the database schema and supports running migrations both `up` and `down`.

**Dbmate  requirements:** 
- file naming convention: `version_description` (e.g. `1_tableCreation`)
- migration file rules:
    - each file must contain migration blocks (`-- migrate:up` and `-- migrate:down`)
    - one file = one transaction block
- more about Dbmate `->` [github](https://github.com/amacneil/dbmate)

### Repository Structure 📂

- [migrations](https://github.com/marmag0/DB-2025-26/tree/main/migrations)
    - [content](https://github.com/marmag0/DB-2025-26/tree/main/migrations/content) 
    - [init](https://github.com/marmag0/DB-2025-26/tree/main/migrations/init)
- [project-plan](https://github.com/marmag0/DB-2025-26/tree/main/project-plan)

### Authors 👨‍🎓
- Mikołaj M `->` [LinkedIn](https://www.linkedin.com/in/mikolaj-mazur/)
    - ...
- Mateusz ... `->`
    - ...