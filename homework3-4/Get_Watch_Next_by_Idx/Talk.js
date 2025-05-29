// Talk.js
// Funzione per recuperare i talk suggeriti per un ID

exports.getRelatedTalks = async (db, talkId) => {
  const collection = db.collection("tedx_rewind_final");

  const talk = await collection.findOne({ _id: talkId });

  if (!talk || !talk.related_talks_id) {
    return null;
  }

  const related = await collection
    .find({ _id: { $in: talk.related_talks_id } })
    .project({ _id: 1, title: 1, semantic_score: 1 })
    .toArray();

  return {
    _id: talk._id,
    title: talk.title,
    related: related.map(r => ({
      id: r._id,
      title: r.title,
      score: r.semantic_score || 0
    }))
  };
};
