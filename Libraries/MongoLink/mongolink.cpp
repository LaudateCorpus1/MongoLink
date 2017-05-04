////////////////////////////////////////////////////////////////////////////////
// MongoLink WL Interface
////////////////////////////////////////////////////////////////////////////////

// #include <map>
#include <assert.h>
#include <stdio.h>

#include <bcon.h>
#include <mongoc.h>
#include <bson.h>

// Source files
#include "wl_common.h"
#include "wl_iterator.h"
#include "wl_bulk_operation.h"
#include "wl_write_concern.h"
#include "wl_bson.h"

#include "wl_database.h"
#include "wl_client.h"
#include "wl_collection.h"

/* Return the version of Library Link */
EXTERN_C DLLEXPORT mint WolframLibrary_getVersion() {
  return WolframLibraryVersion;
}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
  // initialize mongodb
  mongoc_init();
  // Register All Library Managers
  (*libData->registerLibraryExpressionManager)("MongoClient",
                                               manage_instance_mongoclient);
  (*libData->registerLibraryExpressionManager)("MongoDatabase",
                                               manage_instance_mongodatabase);
  (*libData->registerLibraryExpressionManager)("MongoCollection",
                                               manage_instance_mongocollection);
  (*libData->registerLibraryExpressionManager)(
      "MongoBulkOperation", manage_instance_mongobulkoperation);
  (*libData->registerLibraryExpressionManager)(
      "MongoWriteConcern", manage_instance_mongowriteconcern);
  (*libData->registerLibraryExpressionManager)("MongoBSON",
                                               manage_instance_mongobson);
  (*libData->registerLibraryExpressionManager)("MongoIterator",
                                               manage_instance_mongoiterator);
  return 0;
}

EXTERN_C DLLEXPORT void
WolframLibrary_uninitialize(WolframLibraryData libData) {
  // Cleanup mongo
  mongoc_cleanup();
  // Unitialize All Library Managers
  (*libData->unregisterLibraryExpressionManager)("MongoClient");
  (*libData->unregisterLibraryExpressionManager)("MongoDatabase");
  (*libData->unregisterLibraryExpressionManager)("MongoCollection");
  (*libData->unregisterLibraryExpressionManager)("MongoBulkOperation");
  (*libData->unregisterLibraryExpressionManager)("MongoWriteConcern");
  (*libData->unregisterLibraryExpressionManager)("MongoBSON");
  (*libData->unregisterLibraryExpressionManager)("MongoIterator");
  return;
}
