# HW2_MyTEDxRewind_GLUE.py
# Job AWS Glue adattato per progetto MyTEDx Rewind
import pyspark
import sys
import json
from pyspark.sql.functions import col, collect_list, array, array_intersect, size, lit, to_date, year
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame

# 1. Lettura parametri
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# 2. Percorsi S3 dei dataset
base = "s3://mytedx-data"
dataset_path = f"{base}/final_list.csv"
details_path = f"{base}/details.csv"
tags_path = f"{base}/tags.csv"
related_path = f"{base}/related_videos.csv"
images_path = f"{base}/images.csv"

# 3. Lettura dataset principale
talks_df = spark.read.option("header", "true").csv(dataset_path)

# 4. Join con dettagli extra (description, duration, publishedAt)
details_df = spark.read.option("header", "true").csv(details_path)
details_df = details_df.withColumn("publishedAt", to_date(col("publishedAt")))
talks_df = talks_df.join(details_df.withColumnRenamed("id", "id_ref"), talks_df.id == col("id_ref"), "left").drop("id_ref")

# 5. Join con immagini (image URL)
images_df = spark.read.option("header", "true").csv(images_path)
talks_df = talks_df.join(images_df.withColumnRenamed("id", "id_ref"), talks_df.id == col("id_ref"), "left").drop("id_ref")

# 6. Lettura e join con tags
tags_df = spark.read.option("header", "true").csv(tags_path)
tags_grouped = tags_df.groupBy("id").agg(collect_list("tag").alias("tags"))
talks_df = talks_df.join(tags_grouped, "id", "left")

# 7. Join con video correlati
related_df = spark.read.option("header", "true").csv(related_path).dropDuplicates()
related_grouped = related_df.groupBy("id").agg(
    collect_list("related_id").alias("related_talks_id"),
    collect_list("title").alias("related_talks_title")
)
talks_df = talks_df.join(related_grouped, talks_df.id == related_grouped.id, "left").drop(related_grouped.id)

# 8. Filtro per talk vecchi e di valore
temi_target = array(
    lit("education"), lit("innovation"),
    lit("future"), lit("technology")
)

filtered_df = talks_df.filter(
    (talks_df.publishedAt.isNotNull()) &
    (year(col("publishedAt")) < 2020) &
    (size(array_intersect(col("tags"), temi_target)) > 0)
)

# 9. Scrittura finale su MongoDB
output_dynf = DynamicFrame.fromDF(filtered_df, glueContext, "output")
glueContext.write_dynamic_frame.from_options(
    frame=output_dynf,
    connection_type="mongodb",
    connection_options={
        "connectionName": "MyTEDX2025",
        "database": "mytedx_db",
        "collection": "tedx_rewind_final",
        "ssl": "true",
        "ssl.domain_match": "false"
    }
)

job.commit()
