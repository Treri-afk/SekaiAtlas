const express = require('express')
const app = express()
const port = 3000


app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const usersRoutes = require("./routes/users");

app.use("/users", usersRoutes);

const friendsRoutes = require("./routes/friends");

app.use("/friends", friendsRoutes);

const aventureRoutes = require("./routes/aventure");

app.use("/aventure", aventureRoutes);

const photosRouter = require('./routes/photos');

app.use('/photos', photosRouter);




app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`app listening on port ${port}`)
})
