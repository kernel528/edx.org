// index.js
const falcorExpress = require("falcor-express");
const Router = require("falcor-router");

const express = require("express");
const app = express();

app.use(
    "/model.json",
    falcorExpress.dataSourceRoute(function (req, res) {
        // create a Virtual JSON resource with single key ('greeting')
        return new Router([
            {
                // match a request for the key 'greeting'
                route: "greeting",
                // respond with a PathValue with the value of 'Hello World.'
                get: () => ({ path: ["greeting"], value: "Hello World" }),
            },
        ]);
    })
);

// serve static files from current directory
app.use(express.static(__dirname + "/"));

app.listen(3000);