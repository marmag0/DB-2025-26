# DB-2025-26

## HOW TO

`->` navigate to root
`->` start database (migration and tests will run automatically)
`->` first time:
```
docker compose up --build
```
`->` another attempts and restarts:
```
docker compose down
docker compose up
```
`->` access psql CLI
```
docker compose exec db psql -U admin -d postgres
```


## Welcome to our project!

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
    - each file must contain migration blocks: `-- migrate:up` and `-- migrate:down`
    - one file = one transaction block (by default)
    - supports transaction specification options: `transaction:false` and `transaction:true`
- more about Dbmate `->` [GitHub](https://github.com/amacneil/dbmate)


### Automated tests - pgTAP 🧪

To ensure the reliability and correctness of our database, we use [pgTAP](https://pgtap.org/), a powerful testing framework for PostgreSQL. It allows us to write unit tests for database objects such as tables, views, functions, and triggers, ensuring that every component behaves as expected.

**Why pgTAP?**
- **declarative syntax**: write tests in a human-readable format, making it easy to understand and maintain.
- **integration with CI/CD**: seamlessly integrates with continuous integration pipelines to automate test execution.
- **comprehensive coverage**: supports testing for schema integrity, data constraints, and custom business logic.


### Works on mine device... but also works on yours! 💻

- **containerized environment** - the entire stack is orchestrated using `Docker Compose`, ensuring environment parity across different operating systems.
- **automated orchestration** - healthchecks are implemented to guarantee that the dbmate migrator only triggers once the database is fully ready to accept connections.
- **persistent storage** - utilizes named volumes to ensure data persists across container restarts and updates.


### Database Management & Cloud ☁️

The database won't just sit isolated in a container - we are **exposing access via a simple management panel (webapp)**. The entire setup will be hosted on **Google Cloud**, and to avoid exposing the database "butt-naked" to the internet, we’ll use a **Cloudflare Tunnel**. This ensures traffic travels through a secure, encrypted channel directly to our infrastructure, giving us a safe way to manage our tables from anywhere on Earth.

To keep everything secure, access to the panel is restricted via **Google OAuth 2.0**. Only whitelisted Google accounts will be granted entry, ensuring that our **data remains private while providing us with a seamless and safe way to manage tables from anywhere on Earth**.


### Repository Structure 📂

Here's the repository structure - feel free to explore!
Each directory contains a separate `README.md` file, which explains in detail the purpose of the directory and the functionalities available inside it.

- [example-data](https://github.com/marmag0/DB-2025-26/tree/main/example-data) 
- [migrations](https://github.com/marmag0/DB-2025-26/tree/main/migrations)
- [project-plan](https://github.com/marmag0/DB-2025-26/tree/main/project-plan)
- [tests](https://github.com/marmag0/DB-2025-26/tree/main/tests)


### Authors 👨‍🎓
- Mikołaj M `->` [LinkedIn](https://www.linkedin.com/in/mikolaj-mazur/)
- Mateusz K `->` [LinkedIn](https://www.linkedin.com/in/mateusz-klikuszewski/)
