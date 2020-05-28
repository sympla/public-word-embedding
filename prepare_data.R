## Load required packages
library(symplyr)
library(data.table)

## Download pre-trained word embeddings from S3
file_download_from_s3(
   obj.path  = sprintf("%s/models/word2vec/word_embeddings.csv.bz2", Sys.getenv("BUCKET_NAME")),
   file.path = "word_embeddings.csv.bz2"
)

## Decompress data
file_extract_bzip2("word_embeddings.csv.bz2", keep = FALSE, threads = 6)

## Import embeddings
w2v <- file_import_csv("word_embeddings.csv")
unlink("word_embeddings.csv")

## Select 10k words
vocab <- file_import_csv("vocabulary.csv")
w2v <- merge(w2v, vocab, by = "word")
setorder(w2v, rank)
w2v <- w2v[1:1e4,]

## Reduce number precision
num.cols <- names(w2v)[grepl("embeddings_", names(w2v))]
w2v[, (num.cols) := lapply(.SD, round, digits = 4), .SDcols = num.cols]

## Save vectors
file_export_csv(w2v[, num.cols, with = FALSE], "word_embeddings_vectors.tsv", sep = "\t", col.names = FALSE)

## Save metadata
file_export_csv(w2v[, c("word", "rank")], "word_embeddings_metadata.tsv", sep = "\t")
