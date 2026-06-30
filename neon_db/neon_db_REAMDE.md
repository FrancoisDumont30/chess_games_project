# Neon database
Neon is a Postgres database.  

[link](https://neon.com/)  


# database schema

CREATE SCHEMA "public";  
CREATE TABLE "chess_raw_data" (  
	"file_name" text PRIMARY KEY,  
	"json_data" jsonb,  
	"complete" boolean,  
	"loaded_at" timestamp DEFAULT now()  
);  
CREATE UNIQUE INDEX "chess_raw_data_pkey" ON "chess_raw_data" ("file_name");  