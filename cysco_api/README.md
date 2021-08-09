# WiFi Data consumer
This is the Kafka consumer that stores wifi data produced by the TU Delft ICT-data-platform.

## Environmental variables
See the example.env file to see which environmental variables are needed.

## Database
This consumer uses a Postgresql database to store the data and data aggregate.
See the DB folder for the table schemas.

## How to run
`python WificlientDetails_serial.py WiFiclientDetails_Month`