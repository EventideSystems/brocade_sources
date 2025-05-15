# Brocade Sources

A collection of product data sources used to see the Brocade.io service.

## Datakick

Files in `\datakick` include an 'index.csv' containing references for approx. 6500 products, including nutrition data.

Images for products are found in folders with the same GTIN identifier as the product. Not every product has images, but those that do will have one or more image, supplied by users of the datakick.org site.

The Datakick data was licensed by Andrew Kane under a Creative Commons Zero license. Images and data supplied by users was assumed to be provided under the same.

The datakick data was retrieved around 2020-03-28, shortly before the datakick.org site was closed down.


## Product Open Data

Files in `\product_open_data` include data source from http://product-open-data.com/download. The folder contains a number of large files that have been tar/gzipped so they can be stored on Github.

To get the import data for Postgres you can either build the data from the original MySQL dump file, or use the pre-generated `import.sql` file.

### Build import.sql

#### Build from MySQL dump file

First extract `pod_web_2014.01.01_01.sql.gz` in the `\product_open_data` folder.

Run `convert_to_postgres.bash` to generate `import.sql`. NB the bash script is pretty naive - I'd not used `sed` much before. You may need to fiddle with it to get it to work locally.

#### Use the pre-generated file

Simply decompress the `import.sql.gz` file in the `\product_open_data` folder.

### Load the data

Load the data into your local database, adding username or other params as necessary:

`psql [brocade database name] < import.sql`

### Transform the data

If you have loaded into an already setup Brocade database (per https://github.com/ferrisoxide/brocade.io) you can move the Product Open Data data into the Brocade `products` table by running:

`psql [brocade database name] < transform.sql`

NB This only copies over basic details from the `gtin` and `brand` tables.

### Clean up

If required, you can remove the Product Open Data tables, running:

`psql [brocade database name] < cleanup.sql`

## Other Sources

#### POD Database - GS1 Prefix List

A list of GTIN prefixes for each country:

https://pod.opendatasoft.com/explore/dataset/pod_gs1_prefix/information/

NB A number of other interesting datasets can be found at the same site:

https://pod.opendatasoft.com/explore/


#### Open Sources

NB This list needs curation. Some sources may no longer be available. 

* https://github.com/papyrussolution/UhttBarcodeReference
* http://gepir.gs1.org/
* ~~https://www.datakick.org/download~~
* http://product-open-data.com/download
* https://web.archive.org/web/20171227230516/http://www.product-open-data.com:80/download
* ~~https://product.okfn.org/~~
* https://world.openfoodfacts.org/data

#### Restricted / Commerial Sources

* https://upcdatabase.com/
* https://barcodesdatabase.org/
* http://upcspy.com/api/
* https://www.ean-search.org/
* https://upcdatabase.com/docs/faq.asp

#### Metadata / More Information

* https://opendata.stackexchange.com/questions/562/is-there-a-global-database-of-all-products-with-ean-13-barcodes
* https://duckduckgo.com/?q=barcode+database+free&ia=web
* https://github.com/okfn/labs-opd/issues/5
