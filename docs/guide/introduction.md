# Introduction

## What is CMaNGOS Docker?

**CMaNGOS Docker** is a project that aims to provide the **best possible experience** to anyone interested in running their own [**CMaNGOS**](https://cmangos.net/) server.

It doesn't matter if you're a **non-technical newcomer** who just wants to play with friends, a **skilled developer** who wants to experiment with the game world or an **enterprise** looking to deploy multiple realms on a distributed server cluster...  
CMaNGOS Docker will **make things easy** for all of you!

## How does it work?

**CMaNGOS Docker** — as you can tell from the name — is based on [**Docker container**](https://www.docker.com/resources/what-container/) technology, which allows you to run _pre-built_ and _ready-to-use_ applications by simply typing a command into a terminal (among other incredible things).

The main task for the CMaNGOS Docker project is to **maintain** and **provide** these artifacts (called **Docker images**), while yours is simply to run them.

---

Once you've got [Docker installed](/guide/requirements#installation) on your machine, you're done and ready to go!

If it's the first time running the server, you may need some [initial configuration](/guide/getting-started#configure-the-environment) to tell CMaNGOS how you want it to run...  
But even this step is simple and straightforward.

## Why use Docker?

There are several advantages to using Docker containers over the traditional technology stack.  
While I won't cover them all (since that isn't the focus of this document), here are the ones that interest us the most:

- **No further installations required:**
  You won't need to install any additional software, compilers or libraries.

- **No wasted disk space:**
  Docker executables take up around **500–600 MB**, while a typical CMaNGOS Docker image is less than **200 MB**.

- **No wasted time:**
  You won't have to wait for any compilation steps — just download and run immediately.

- **No differences between operating systems:**
  It doesn't matter what OS you're using: Docker works **everywhere**.

---

_That's it. Simple as that._
