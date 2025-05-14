talks_df = spark.read.csv("s3://mytedx/talks.csv", header=True)
watch_df = spark.read.csv("s3://mytedx/watch_next.csv", header=True)
transcripts_df = spark.read.csv("s3://mytedx/transcripts.csv", header=True)

full_data = talks_df.join(watch_df, talks_df.id == watch_df.talk_id, "left")
full_data = full_data.join(transcripts_df, "id", "left")

def calcola_score(descrizione):
    if "hope" in descrizione.lower():
        return 85
    elif "future" in descrizione.lower():
        return 75
    else:
        return 60

from pyspark.sql.functions import udf
from pyspark.sql.types import IntegerType
udf_score = udf(calcola_score, IntegerType())
full_data = full_data.withColumn("score", udf_score(full_data["description"]))

full_data.write.format("mongo").mode("append").option("uri", "mongodb+srv://<utente>:<password>@cluster.mongodb.net/tedx").save()
