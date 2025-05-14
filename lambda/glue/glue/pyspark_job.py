import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from awsglue.context import GlueContext
from awsglue.job import Job

# Inizializzazione contesti Glue
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Caricamento dataset TEDx
talks_df = spark.read.option("header", "true").csv("s3://mytedx/talks.csv")
watch_df = spark.read.option("header", "true").csv("s3://mytedx/watch_next.csv")
transcripts_df = spark.read.option("header", "true").csv("s3://mytedx/transcripts.csv")

# Unione dei dati
talks_with_watch = talks_df.join(watch_df, talks_df.id == watch_df.talk_id, "left")
full_data = talks_with_watch.join(transcripts_df, "id", "left")

# Funzione per simulare sentiment
def calcola_score(descrizione):
    if descrizione and "hope" in descrizione.lower():
        return 85
    elif descrizione and "future" in descrizione.lower():
        return 75
    else:
        return 60

from pyspark.sql.functions import udf
from pyspark.sql.types import IntegerType

udf_score = udf(calcola_score, IntegerType())
full_data = full_data.withColumn("score", udf_score(full_data["description"]))

# Esportazione dati su MongoDB
full_data.write.format("mongo").mode("append").option("uri", "mongodb+srv://<utente>:<password>@cluster.mongodb.net/tedx").save()

job.commit()
