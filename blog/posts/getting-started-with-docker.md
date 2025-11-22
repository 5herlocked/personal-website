# Getting Started with Docker

Docker has revolutionized the way we build, ship, and run applications. If you're new to containerization, this guide will help you get started with the basics.

## What is Docker?

Docker is a platform that allows you to package applications and their dependencies into lightweight, portable containers. Think of containers as standardized units that include everything your application needs to run.

### Key Benefits

- **Consistency** - "Works on my machine" becomes a thing of the past
- **Isolation** - Each container runs in its own environment
- **Portability** - Run the same container anywhere Docker is installed
- **Efficiency** - Containers are lightweight compared to virtual machines

## Basic Concepts

### Images vs Containers

An **image** is a blueprint - it's the template that contains your application and all its dependencies.

A **container** is a running instance of an image - it's your application actually executing.

```bash
# Pull an image from Docker Hub
docker pull nginx

# Run a container from the image
docker run -d -p 80:80 nginx
```

### Dockerfile

A Dockerfile is a text file that contains instructions for building a Docker image:

```dockerfile
# Use an official base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
```

## Essential Docker Commands

Here are the commands you'll use most frequently:

### Working with Images

```bash
# List images
docker images

# Build an image
docker build -t myapp:latest .

# Remove an image
docker rmi myapp:latest
```

### Working with Containers

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop a container
docker stop container_id

# Remove a container
docker rm container_id

# View container logs
docker logs container_id
```

## Docker Compose

For multi-container applications, Docker Compose is your friend. It allows you to define and run multiple containers with a single configuration file.

Example `docker-compose.yml`:

```yaml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    networks:
      - webnet

  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    networks:
      - webnet

networks:
  webnet:
```

Run it with:

```bash
docker-compose up -d
```

## Best Practices

1. **Use official images** when possible as base images
2. **Keep images small** - use alpine variants and multi-stage builds
3. **Don't run as root** - create a non-root user in your Dockerfile
4. **Use .dockerignore** - exclude unnecessary files from the build context
5. **Tag your images** - use semantic versioning for better tracking

## Next Steps

Now that you understand the basics, try:

- Building your own Dockerfile for a simple application
- Setting up a multi-container application with Docker Compose
- Exploring Docker Hub for pre-built images
- Learning about Docker networks and volumes

## Conclusion

Docker is a powerful tool that simplifies application deployment and management. With these basics, you're ready to start containerizing your applications and experiencing the benefits firsthand.

Happy containerizing!

---

*Published: November 20, 2025*
