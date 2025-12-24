const express = require("express");
const app = express();

app.get("/", (req, res) => res.json({ message: "hello from ecs" }));
app.get("/health", (req, res) => res.status(200).send("ok"));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`listening on ${port}`));

// For testing locally