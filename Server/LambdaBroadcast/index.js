console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var moment = require('moment');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();
var s3 = new AWS.S3();

function process(bucket, key, bid, seq, callback) {
	seq = parseInt(seq);

	s3.getObject({ Bucket: bucket, Key: key}, function(err, data) {
		if(err) {
			callback(err, null);
		} else {
			var now = moment().utc().format('X');
			var metadata = data.Metadata;

			console.log("metadata: " + util.inspect(metadata, { showHidden: true, depth: 10 }));
			var live = metadata["last-file"] == "0" ? "1" : "0";

			if(seq == 0) {
				var json = JSON.parse(data.Body.toString());

				console.log("json: " + util.inspect(json));

				// Add DDB record
				dynamodb.putItem({
					TableName: config.DDB_BROADCAST_TABLE,
					Item: {
						bid: { S: bid },
						version: { N: json.version.toString() },
						created: { N: now },
						updated: { N: now },
						sequence: { N: seq.toString() },
						user: { S: json.user },
						name: { S: json.name },
						language: { S: json.language },
						lat: { S: json.lat },
						lon: { S: json.lon },
						city: { S: json.city },
						state: { S: json.state },
						country: { S: json.country },
						rate: { N: json.rate.toString() },
						bits: { N: json.bits.toString() },
						channels: { N: json.channels.toString() },
						compression: { S: json.compression },
						segment_duration: { N: json.segment_duration.toString() },
						live: { N: live }
					},
					ConditionExpression: 'attribute_not_exists (bid)',
					ReturnValues: 'NONE'
				}, function(err, data) {
					console.log(err);
					if(err) callback(err, null);
					else callback(null, data);
				});
			} else {
				// Update DDB record
				dynamodb.updateItem({
					TableName: config.DDB_BROADCAST_TABLE,
					Key: { bid: { S: bid }},
					AttributeUpdates: { updated: { Action: 'PUT',
												   Value: { N: now } },
										sequence: { Action: 'PUT',
													Value: { N: seq.toString() } },
										live: { Action: 'PUT',
													Value: { N: live } },
									  },
					Expected: {	live: { ComparisonOperator: 'NE', AttributeValueList: [ { N: '0' } ] },
								sequence: { ComparisonOperator: 'LE', AttributeValueList: [ { N: seq.toString() } ] }
					},
					ReturnValues: 'NONE'
				}, function(err, data) {
					if(err) console.log("updateItem error: %j", err);
					if(err) callback(err, null);
					else callback(null, data);
				});	
			}

		}
	});
}

// Filename format
//	 B077647E-F1A6-419B-906D-065F4E55A58D/1-000003
//   test/*
exports.handler = function(event, context) {
    var bucket = event.Records[0].s3.bucket.name;
    var key = event.Records[0].s3.object.key;
    console.log("bucket = " + bucket);
    console.log("key = " + key);

    var parts = key.split('/');
    if(parts[0] == "test" && key != "test/")
    {
		s3.deleteObject({ Bucket: bucket, Key: key}, function(err, data) {
			if(err) context.fail({success:false, error:err});
			else context.succeed({success:true, message:'Deleted test file'});
		});
    }
    else if(parts.length == 2) {
    	process(bucket, key, parts[0], parts[1], function(err, result) {
    		if(err) context.fail({success:false, error:err});
    		else context.succeed({success: true});
    	});
    } else {
    	context.fail({success:false, error:'Invalid file name: ' + key});
    }
}
