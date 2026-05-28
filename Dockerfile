# Below is the single stage docker file which as size 218 MB -> 1min 50 sec time Jenkins was takign to build this large size dockerfile

# Use Node.js Alpine base image
#FROM node:alpine

# Create and set the working directory inside the container
#WORKDIR /app

# Copy package.json and package-lock.json to the working directory
#COPY package.json package-lock.json /app/

# Install dependencies
#RUN npm install

# Copy the entire codebase to the working directory
#COPY . /app/

# Expose the port your container app
#EXPOSE 3000    

# Define the command to start your application (replace "start" with the actual command to start your app)
#CMD ["npm", "start"]



# In order to reduce the docker image size, need to implement multi stage dockerfile. Below is the implementation.
# Using Multistage docker image size becomes 26.4 MB from 218 MB

# BUILD STAGE
# Use Node.js Alpine base image
FROM node:alpine AS builder

# Create and set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json /app/

# Install dependencies
RUN npm install

COPY . .

RUN npm run build


# PRODUCTION STAGE
FROM nginx:alpine

COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

# daemon off = run nginx in foreground mode
CMD [ "nginx", "-g", "daemon off;" ] 
