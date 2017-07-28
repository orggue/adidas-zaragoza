### Setup Example Application 

```
cd nodejs-example/

const express = require('express')
const app = express()

app.get('/', function (req, res) {
  res.send('Hello World')
})

app.listen(9000, function () {
  console.log('Listening on port 9000')
})
```

----

Create Dockerfile

```
FROM mhart/alpine-node:6

WORKDIR /app
ADD . .

RUN npm install

EXPOSE 8000
CMD ["node", "app.js"]
```

----

Build Docker image

```
docker build -t my_nodejs_image .
docker run -d -p 9000:9000 my_nodejs_image
```

----

Test

```
curl localhost:9000
Hello World
```

----

Next, we'll need to setup a Docker Registry to store our images.

```
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

Open http://localhost:5000 in a browser.

----

Before we can push our nodejs image to the registry we will need to tag it appropriately.

```
docker tag my_nodejs_image:latest localhost:5000/my_nodejs_image 
docker push localhost:5000/my_nodejs_image
```

And validate the image is now in our repo:
```
docker images localhost:5000/my_nodejs_image
```

Or open a browser to : `http://localhost:5000/v2/_catalog`

----

Clean up registry

```
docker rm -f $(docker ps -ql)
```

----

[Next up setup GitLab...](../04_gitlab.md)
