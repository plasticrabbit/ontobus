date
rm *.test
rm *.agent
dmd -Iimport src/*.d lib/TripleStorage.a lib/librabbitmq_client.a lib/librabbitmq.a -O -release -ofSemargl.test
#dmd src/Triple.d src/TripleStorage.d src/Log.d src/HashMap.d src/Hash.d src/librabbitmq_headers.d src/librabbitmq_listen.d src/server.d lib/librabbitmq.a -O -release -ofSemargl.agent
rm hashMap.log
rm *.o
date
