FROM node:16

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

RUN npm install -g serve

#Start server
CMD ["serve", "-s", "build", "-l", "3000"]

EXPOSE 3000
