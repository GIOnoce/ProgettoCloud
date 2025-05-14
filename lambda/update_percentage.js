exports.handler = async (event) => {
  const { id, newScore } = event;
  const talk = await collection.findOne({ id });
  const updatedScore = (talk.score * 0.8) + (newScore * 0.2);
  await collection.updateOne({ id }, { $set: { score: updatedScore } });
  return { id, oldScore: talk.score, newScore: updatedScore };
};
