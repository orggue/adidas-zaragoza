FROM mhart/alpine-node:6

WORKDIR /app
ADD . .

RUN npm install

EXPOSE 9000
CMD ["node", "app.js"]