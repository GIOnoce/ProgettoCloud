import sys
import json
import pyspark
from pyspark.sql.functions import (
    col, collect_list, array_join, when, isnan, isnull, 
    broadcast, explode, struct, collect_set, size, desc, lit, array
)
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, ArrayType
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

# Percorsi dei file
tedx_dataset_path = "s3://tedx-2025-data-mio/final_list.csv"
details_dataset_path = "s3://tedx-2025-data-mio/details.csv"
tags_dataset_path = "s3://tedx-2025-data-mio/tags.csv"
related_videos_path = "s3://tedx-2025-data-mio/related_videos.csv"

args = getResolvedOptions(sys.argv, ['JOB_NAME'])


sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
    
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

print("Starting TEDx data processing job...")

print("Reading main dataset...")
tedx_dataset = spark.read \
    .option("header", "true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(tedx_dataset_path)
    
tedx_dataset.printSchema()

count_items = tedx_dataset.count()
count_items_null = tedx_dataset.filter("id is not null").count()
print(f"Number of items from RAW DATA: {count_items}")
print(f"Number of items from RAW DATA with NOT NULL KEY: {count_items_null}")

print("Reading details dataset...")
details_dataset = spark.read \
    .option("header", "true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(details_dataset_path)

details_dataset = details_dataset.select(
    col("id").alias("id_ref"),
    col("description"),
    col("duration"),
    col("socialDescription"),
    col("presenterDisplayName"),
    col("publishedAt")
)

# Join con la tabella principale
print("Joining main dataset with details...")
tedx_dataset_main = tedx_dataset.join(
    details_dataset, 
    tedx_dataset.id == details_dataset.id_ref, 
    "left"
).drop("id_ref")

tedx_dataset_main.printSchema()

print("Reading and aggregating tags...")
tags_dataset = spark.read.option("header", "true").csv(tags_dataset_path)

tags_dataset_agg = tags_dataset.groupBy(col("id").alias("id_ref")).agg(
    collect_list("tag").alias("tags")
)

print("Joining with tags...")
tedx_dataset_with_tags = tedx_dataset_main.join(
    tags_dataset_agg, 
    tedx_dataset_main.id == tags_dataset_agg.id_ref, 
    "left"
).drop("id_ref")

print("Reading related videos dataset...")
related_videos = spark.read \
    .option("header", "true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(related_videos_path)

related_videos.printSchema()

print("Processing related videos relationships...")

# Crea punteggio semantico basato su viewedCount 
related_videos_processed = related_videos.select(
    col("id").alias("main_id"),
    struct(
        col("related_id").alias("id"),
        when(col("viewedCount").isNotNull(), 
             col("viewedCount").cast(DoubleType()) / 1000000.0)
        .otherwise(lit(0.5)).alias("score"),
        col("title").alias("title"),
        col("presenterDisplayName").alias("presenter")
    ).alias("related_talk")
)

related_talks_agg = related_videos_processed.groupBy("main_id").agg(
    collect_list("related_talk").alias("related_talks_raw")
)

print("Aggregating related talks with scoring...")

# Funzione per ordinare e limitare i video correlati
from pyspark.sql.functions import udf
from pyspark.sql.types import ArrayType, StructType, StructField

def sort_and_limit_related_talks(talks_list, limit=10):
    if not talks_list:
        return []
    
    sorted_talks = sorted(talks_list, key=lambda x: x['score'] if x['score'] is not None else 0, reverse=True)
    
    return sorted_talks[:limit]

sort_related_talks_udf = udf(
    lambda talks: sort_and_limit_related_talks(talks, 10),
    ArrayType(StructType([
        StructField("id", StringType(), True),
        StructField("score", DoubleType(), True),
        StructField("title", StringType(), True),
        StructField("presenter", StringType(), True)
    ]))
)

related_talks_final = related_talks_agg.withColumn(
    "related_talks",
    sort_related_talks_udf(col("related_talks_raw"))
).select("main_id", "related_talks")

print("Joining main dataset with related talks...")

tedx_dataset_final = tedx_dataset_with_tags.join(
    related_talks_final,
    tedx_dataset_with_tags.id == related_talks_final.main_id,
    "left"
).drop("main_id")

# Gestisci video senza video correlati
tedx_dataset_final = tedx_dataset_final.withColumn(
    "related_talks",
    when(col("related_talks").isNull(), array()).otherwise(col("related_talks"))
)

# Prepara dataset finale per MongoDB
tedx_dataset_agg = tedx_dataset_final.select(
    col("id").alias("_id"), 
    col("*")
).drop("id")

print("Final dataset schema:")
tedx_dataset_agg.printSchema()

print("Sample data:")
tedx_dataset_agg.show(5, truncate=False)

print(f"Total records to be written: {tedx_dataset_agg.count()}")
print(f"Records with related talks: {tedx_dataset_agg.filter(size(col('related_talks')) > 0).count()}")

# Scrittura su MongoDB
print("Writing to MongoDB...")
write_mongo_options = {
    "connectionName": "TEDx",
    "database": "unibg_tedx_2025",
    "collection": "tedx_data",
    "ssl": "true",
    "ssl.domain_match": "false"
}

tedx_dataset_dynamic_frame = DynamicFrame.fromDF(tedx_dataset_agg, glueContext, "nested")

glueContext.write_dynamic_frame.from_options(
    tedx_dataset_dynamic_frame, 
    connection_type="mongodb", 
    connection_options=write_mongo_options
)

print("Job completed successfully!")

job.commit()
