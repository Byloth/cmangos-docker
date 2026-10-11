# Requirements

::: warning Prerequisites
All the contents of this guide assume a basic knowledge of your **operating system**, its **terminal**, and how to use its **command line interface**.

These topics won't be covered in this documentation; however, any other software or tools used will be described within the limited scope of their specific implementation.
:::

## Docker

[**Docker**](https://www.docker.com/) is the only software required to run this project.

### Installation

To install Docker, visit the official [**download page**](https://docs.docker.com/get-docker/) and select your operating system.  
The installer will begin downloading; once complete, run it and follow the prompts.

### Verifying the installation

To check whether the installation was successful, open a terminal or command prompt and type:

```sh
docker run --rm hello-world
```

You should see output similar to the following:

```
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
2db29710123e: Pull complete
Digest: sha256:aa0cc8055b82dc2509bed2e19b275c8f463506616377219d9642221ab53cf9fe
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

::: tip Linux users
If you're using a Linux-based operating system, you'll probably need to prepend `sudo` to each `docker` command you run. Due to the way Docker works in a Linux environment, it requires superuser privileges.

[Learn how to run Docker without sudo →](https://docs.docker.com/engine/install/linux-postinstall/)
:::
