exports.analyze = (req, res) => {
  let message = req.query.message || req.body.message || "Hi World!";
  res.status(200).send(message);
};
