#!/bin/sh
rm *.o
rm rodzilla

#dmd -unittest -O src/rodzilla.d src/ListOntoFunctions.d src/MessageParser.d  src/Triple.d src/OntoFunction.d src/ListStrings.d src/ListTriples.d 

dmd -unittest -O src/rodzilla.d src/librabbitmq_headers.d src/librabbitmq_client.d lib/librabbitmq.a 

dmd src/librabbitmq_client.d src/librabbitmq_headers.d -O -Hdexport -release -lib

./rodzilla