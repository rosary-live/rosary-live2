console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var moment = require('moment');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();
var s3 = new AWS.S3();

// Sequence 0 file format
// {
// "version": 1,
// "bid": "12345-67890",
// "start": 1,
// "language": "en",
// "user": "test@test.com",
// "name": "john doe",
// "avatar": "URL",
// "lat": "1.2",
// "lon": "3.4",
// "city": "Olathe",
// "state": "KS",
// "country": "US",
// "rate": 22100,
// "bits": 8,
// "channels": 1,
// "compression": "ACC",
// "segment_duration": 10000
// }

function process(bucket, key, bid, seq, callback) {
	seq = parseInt(seq);

	if(seq == 0) {
		s3.getObject({ Bucket: bucket, Key: key}, function(err, data) {
			if(err) {
				callback(err, null);
			} else {
				var json = JSON.parse(data.Body.toString());

				var now = moment().utc().format('X');
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
						segment_duration: { N: json.segment_duration.toString() }
					},
					ConditionExpression: 'attribute_not_exists (bid)',
					ReturnValues: 'NONE'
				}, function(err, data) {
					if(err) callback(err, null);
					else callback(null, data);
				});		
			}
		});		
	} else {
		var now = moment().utc().format('X');

		// Update DDB record
		dynamodb.updateItem({
			TableName: config.DDB_BROADCAST_TABLE,
			Key: { bid: { S: bid }},
			AttributeUpdates: { updated: { Action: 'PUT',
										   Value: { N: now } },
								sequence: { Action: 'PUT',
											Value: { N: seq.toString() } }
							  },
			ReturnValues: 'NONE'
		}, function(err, data) {
			if(err) callback(err, null);
			else callback(null, data);
		});	
	}
}

// Filename format
//	 <broadcast id GUID>/<sequence number 0...n>
// 
exports.handler = function(event, context) {
    var bucket = event.Records[0].s3.bucket.name;
    var key = event.Records[0].s3.object.key;
    console.log("bucket = " + bucket);
    console.log("key = " + key);

    var parts = key.split('/');
    if(parts.length == 2) {
    	process(bucket, key, parts[0], parts[1], function(err, result) {
    		if(err) context.fail(err);
    		else context.succeed(result);
    	});
    } else {
    	context.fail('Invalid file name: ' + key);
    }
}
