
 #  Plsm configs are used to drive the extraction process. Below are what each field means:
 #    * module_name -> This is the name of the module that the models will be placed under
 #    * destination -> The output location for the generated models  
 #    * server -> this is the name of the server that you are connecting to. It can be a DNS name or an IP Address. This needs to be filled in as there are no defaults
 #    * port -> The port that the database server is listening on. This needs to be provided as there may not be a default for your server
 #    * database_name -> the name of the database that you are connecting to. This is required.
 #    * username -> The username that is used to connect. Make sure that there is sufficient privelages to be able to connect, query tables as well as query information schemas on the database. The schema information is used to find the index/keys on each table
 #    * password -> This is necessary as there is no default nor is there any handling of a blank password currently.
 #    * type -> This dictates which database vendor you are using. We currently support PostgreSQL and MySQL. If no value is entered then it will default to MySQL. Do note that this is an atom and not a string


config :plsm,
module_name: "module name",
destination: "output path",
server: "localhost",
port: "3306",
database_name: "name of database",
username: "username",
password: "password",
type: :tds