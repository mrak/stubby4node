FROM node:latest

WORKDIR /stubby
COPY package.json /stubby

RUN npm i

COPY . /stubby

EXPOSE 7443 8882 8889
CMD npm start