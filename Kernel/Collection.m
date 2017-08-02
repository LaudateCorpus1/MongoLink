(*******************************************************************************
Collection level-functions

*******************************************************************************)

Package["MongoLink`"]

PackageImport["GeneralUtilities`"]

(*----------------------------------------------------------------------------*)
(****** Load Library Functions ******)

clientGetCollection = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_ClientGetCollection", 
	{
		Integer,		(* client handle *)
		Integer,		(* collection handle *)
		"UTF8String",	(* database name *)
		"UTF8String"	(* collection name *)

	},
	"Void"						
]

databaseGetCollection = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_DatabaseGetCollection", 
	{
		Integer,		(* database handle *)
		Integer,		(* collection handle *)
		"UTF8String"	(* collection name *)

	}, 
	"Void"						
]

mongoCollectionCount = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionCount", 
	{
		Integer,		(* connection handle *)
		Integer			(* bson handle *)
	}, 
	Integer				(* count *)						
]	

mongoCollectionFind = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionFind", 
	{
		Integer,		(* connection handle *)
		Integer,		(* query *)
		Integer,		(* opts *)		
		Integer			(* output iterator handle *)
	}, 
	"Void"				
]

mongoCollectionName = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_CollectionGetName", 
	{
		Integer			(* collection handle *)
	}, 
	"UTF8String"		(* name *)						
]	

mongoCollectionCreateBulkOp = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionCreateBulkOp", 
	{
		Integer,		(* collection handle *)
		Integer,		(* ordered *)
		Integer,		(* write concern *)
		Integer			(* output bulk op handle key *)
	}, 
	"Void"				
]

mongoCollectionUpdate = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionUpdate", 
	{
		Integer,		(* collection handle *)
		Integer,		(* selector bson handle *)
		Integer,		(* update bson handle *)
		Integer,		(* write concern handle *)
		Integer,		(* upsert *)
		Integer			(* Multi *)
	}, 
	"Void"				
]	

mongoCollectionRemove = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionRemove", 
	{
		Integer,		(* collection handle *)
		Integer,		(* delete single *)
		Integer,		(* selector bson handle *)
		Integer			(* write concern handle *)
	}, 
	"Void"				
]	

mongoCollectionAggregate = LibraryFunctionLoad[$MongoLinkLib, 
	"WL_MongoCollectionAggregation", 
	{
		Integer,		(* connection handle *)
		Integer,		(* pipeline bson *)
		Integer			(* iterator *)
	
	}, 
	"Void"				
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionObject"]

(* This is a utility function defined in GeneralUtilities, which makes a nicely
formatted display box *)
DefineCustomBoxes[MongoCollectionObject, 
	e:MongoCollectionObject[handle_, dbasename_, collname_, base_] :> Block[{},
	BoxForm`ArrangeSummaryBox[
		MongoCollectionObject, e, None, 
		{
			BoxForm`SummaryItem[{"ID: ", ManagedLibraryExpressionID[handle]}],
			BoxForm`SummaryItem[{"Name: ", collname}],
			BoxForm`SummaryItem[{"Database: ", dbasename}]
		},
		{},
		StandardForm
	]
]];

PackageExport["MongoCollectionName"]
MongoCollectionName[MongoCollectionObject[__, collname_, _]] := collname;
MongoCollectionName[___] := $Failed

MongoCollectionObject /: RandomSample[coll_MongoCollectionObject, n_] := Module[
	{pipeline}
	,
	pipeline = {<|"$sample" -> <|"size" -> n|>|>};
	MongoCollectionAggregate[coll, pipeline]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoGetCollection"]

MongoGetCollection[database_MongoDatabaseObject, collectionName_String] := Catch @ Module[
	{collectionHandle, result},
	(* Check that collectionName is in database *)
 
	collectionHandle = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = safeLibraryInvoke[databaseGetCollection,
		ManagedLibraryExpressionID @ MongoDatabaseHandle[database], 
		ManagedLibraryExpressionID[collectionHandle],
		collectionName
	];
	MongoCollectionObject[collectionHandle, MongoDatabaseName[database], collectionName, database]
]

MongoGetCollection[client_MongoClientObject, databaseName_String, collectionName_String] := Catch @ Module[
	{collectionHandle, result},
	collectionHandle = CreateManagedLibraryExpression["MongoCollection", MongoCollection];
	result = safeLibraryInvoke[clientGetCollection,
		ManagedLibraryExpressionID[client], 
		ManagedLibraryExpressionID[collectionHandle],
		databaseName, 
		collectionName
	];
	MongoCollectionObject[collectionHandle, databaseName, collectionName, client]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionName"]

MongoCollectionName[MongoCollectionObject[handle_, ___]] := Catch @ 
	safeLibraryInvoke[mongoCollectionName, ManagedLibraryExpressionID[handle]];

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionCount"]

MongoCollectionCount[MongoCollectionObject[handle_, ___], query_Association] := Catch @ Module[
	{bsonQuery},
	bsonQuery = iBSONCreate[query];
	safeLibraryInvoke[mongoCollectionCount,
		ManagedLibraryExpressionID[handle], 
		ManagedLibraryExpressionID[First @ bsonQuery]
	]
]

MongoCollectionCount[collection_MongoCollectionObject] := 
	MongoCollectionCount[collection, <||>]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionFind"]

Options[MongoCollectionFind] = {
};

MongoCollectionFind[collection_MongoCollectionObject, 
	query_, opts:OptionsPattern[]] := Catch @ Module[
	{queryBSON, optsBSON, iteratorHandle, optsAssoc},
	iteratorHandle = CreateManagedLibraryExpression["MongoIterator", MongoIterator];
	(* Create BSON query + field docs *)
	queryBSON = iBSONCreate[query];
	optsAssoc = <||>; (* add this in future! *)
	optsBSON = iBSONCreate[optsAssoc];

	safeLibraryInvoke[mongoCollectionFind,
		ManagedLibraryExpressionID[First @ collection], 
		ManagedLibraryExpressionID[First @ queryBSON],
		ManagedLibraryExpressionID[First @ optsBSON],
		ManagedLibraryExpressionID[iteratorHandle]
	];
	
	(* Return iterator object *)
	NewIterator[
		MongoIterator, 
		{iter = iteratorHandle}, 
		Replace[
			MongoIteratorRead[iter], 
			$Failed :> IteratorExhausted
		]
	]
]

MongoCollectionFind[collection_MongoCollectionObject, opts:OptionsPattern[]] := 
	MongoCollectionFind[collection, <||>, opts]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionInsert"]

Options[MongoCollectionInsert] = {
	"WriteConcern" -> Automatic,
	"Ordered" -> True
};

MongoCollectionInsert::ordered = 
	"The option \"Ordered\" was ``, but must be either True or False.";
MongoCollectionInsert::writeconcern = 
	"The option \"WriteConcern\" was ``, but must be a MongoWriteConcernObject or Automatic.";

MongoCollectionInsert[coll_MongoCollectionObject, doc_, opts:OptionsPattern[]] := Catch @ Module[
	{wc, ordered},
	(** parse options **)
	{wc, ordered} = OptionValue[{"WriteConcern", "Ordered"}];
	If[!BooleanQ[ordered],
		Message[MongoCollectionInsert::ordered, ordered];
		Throw[$Failed]
	];
	If[(wc =!= Automatic) && (Head[wc] =!= MongoWriteConcernObject),
		Message[MongoCollectionInsert::writeconcern, writeconcern];
		Throw[$Failed]
	];
	iMongoCollectionInsert[coll, doc, wc, ordered]
]

iMongoCollectionInsert[
	collection_MongoCollectionObject, docs:{__BSONObject}, wc_, ordered_] := Module[
	{writeConcern, bulkHandle}
	,
	(* Write concern: if Automatic, create Null ManagedLibraryExpression *)
	writeConcern = If[wc === Automatic, 
		CreateManagedLibraryExpression["MongoWriteConcern", MongoWriteConcern],
		First[writeConcern]
	];
	(* Create bulk op *)
	bulkHandle = CreateManagedLibraryExpression["MongoBulkOperation", MongoBulkOperation];
	safeLibraryInvoke[mongoCollectionCreateBulkOp,
		ManagedLibraryExpressionID[First @ collection],
		Boole[ordered],
		ManagedLibraryExpressionID[writeConcern],
		ManagedLibraryExpressionID[bulkHandle]
	];
	Scan[
		bulkOperationInsert[bulkHandle, #]&,
		docs
	];
	(* Execute *)
	bulkOperationExecute[bulkHandle]
]

iMongoCollectionInsert[coll_MongoCollectionObject, doc_BSONObject, wc_, ordered_] := 
	iMongoCollectionInsert[coll, {doc}, wc, ordered]

iMongoCollectionInsert[coll_MongoCollectionObject, doc_Association|doc_String, wc_, ordered_] := 
	iMongoCollectionInsert[coll, {iBSONCreate[doc]}, wc, ordered]

iMongoCollectionInsert[coll_MongoCollectionObject, doc_List, wc_, ordered_] := 
	iMongoCollectionInsert[coll, iBSONCreate /@ doc, wc, ordered]

iMongoCollectionInsert::invtype =
	"Document to be inserted must be an Association, String or BSONObject, or a list of these.";
iMongoCollectionInsert[coll_MongoCollectionObject, doc_, wc_, ordered_] := 
	(Message[iMongoCollectionInsert::invtype];Throw[$Failed])

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionUpdate"]

SetUsage[MongoCollectionUpdate, "
MongoCollectionUpdate[MongoCollection[$$], query$, update$] update a single document in the \
collection MongoCollection[$$] which satisfies the query$ association. The update$ document \
will replace the contents of the matched document (exept for _id field). To update only \
individual fields, use the $set operator. If no document satisfies query$, nothing is done, unless \
the Option \"Upsert\" is set to True. To update all documents satisfying the query$, set the option \
\"MultiDocumentUpdate\" to True."
]

Options[MongoCollectionUpdate] = {
	"WriteConcern" -> 1,
	"Journal" -> True,
	"Timeout" -> None,
	"Upsert" -> False,
	"MultiDocumentUpdate" -> False
};

MongoCollectionUpdate[MongoCollectionObject[handle_, ___], 
	selector_, updaterDoc_, OptionsPattern[]] := Catch @ Module[
	{queryBSON, updaterDocBSON},
		
	(* Write concern *)
	writeConcern = WriteConcernCreate[
		OptionValue["WriteConcern"], 
		"Journal" -> OptionValue["Journal"], 
		"Timeout" -> OptionValue["Timeout"]
	];
	If[FailureQ[writeConcern], Return[writeConcern]];

	(* Create BSON query + update docs *)
	queryBSON = iBSONCreate[selector];
	updaterDocBSON = iBSONCreate[updaterDoc];

	upsert = OptionValue["Upsert"];
	multiDocumentUpdate = OptionValue["MultiDocumentUpdate"];

	(* Execute *)
	result = safeLibraryInvoke[mongoCollectionUpdate,
		ManagedLibraryExpressionID[handle],
		ManagedLibraryExpressionID[First @ queryBSON],
		ManagedLibraryExpressionID[First @ updaterDocBSON],
		ManagedLibraryExpressionID[writeConcern],
		Boole[upsert],
		Boole[multiDocumentUpdate]
	];
	result
]	
(*----------------------------------------------------------------------------*)

PackageExport["MongoCollectionRemove"]

SetUsage[MongoCollectionRemove, "
MongoCollectionRemove[MongoCollection[$$], query$] removes a single document from MongoCollection[$$] \
that satisfies the query $query. To remove all documents, set the Option \"MultiDocumentUpdate\" to \ 
True."
]

Options[MongoCollectionRemove] =
{
	"WriteConcern" -> 1,
	"Journal" -> True,
	"Timeout" -> None,
	"MultiDocumentUpdate" -> False
};

MongoCollectionRemove[MongoCollectionObject[handle_, ___], 
	selector_, OptionsPattern[]] := Catch @ Module[
	{queryBSON, multiDocumentUpdate, writeConcern},
	(* Write concern *)
	writeConcern = WriteConcernCreate[
		OptionValue["WriteConcern"], 
		"Journal" -> OptionValue["Journal"], 
		"Timeout" -> OptionValue["Timeout"]
	];
	If[FailureQ[writeConcern], Return[writeConcern]];

	(* Create BSON query *)
	queryBSON = iBSONCreate[selector];
	multiDocumentUpdate = OptionValue["MultiDocumentUpdate"];
	(* Execute *)
	result = safeLibraryInvoke[mongoCollectionRemove,
		ManagedLibraryExpressionID[handle],
		Boole[multiDocumentUpdate],
		ManagedLibraryExpressionID[First @ queryBSON],
		ManagedLibraryExpressionID[writeConcern]
	];
	result
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoCollectionAggregate"]

MongoCollectionAggregate[collection_MongoCollectionObject, pipeline_] := Module[
	{iteratorHandle, pipelineBSON},
	iteratorHandle = CreateManagedLibraryExpression["MongoIterator", MongoIterator];
	pipelineBSON = iBSONCreate[<|"pipeline" -> pipeline|>];

	safeLibraryInvoke[mongoCollectionAggregate,
		ManagedLibraryExpressionID[First @ collection], 
		ManagedLibraryExpressionID[First @ pipelineBSON], 
		ManagedLibraryExpressionID[iteratorHandle]
	];

	(* Return iterator object *)
	NewIterator[
		MongoIterator, 
		{iter = iteratorHandle}, 
		Replace[
			MongoIteratorRead[iter], 
			$Failed :> IteratorExhausted
		]
	]
]

(*----------------------------------------------------------------------------*)
PackageExport["MongoReferenceGet"]

SetUsage[MongoReferenceGet, "
MongoReferenceGet[MongoDatabase[$$], MongoReference[$$]] returns the corresponding document \
referenced by MongoReference[$$].
"
]

MongoReferenceGet[database_MongoDatabaseObject, mong_MongoDBReference] := Catch @ Module[
	{coll, docIter},
	coll = MongoGetCollection[database, First@mong];
	docIter = MongoCollectionFind[coll, <|"_id" -> <|"$oid" -> Last[mong]|>|>];
	If[FailureQ[docIter], Return[$Failed]];
	Read[docIter]
]

