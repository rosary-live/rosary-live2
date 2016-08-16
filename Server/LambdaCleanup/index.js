console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();

function process(bucket, key, bid, seq, callback) {
	seq = parseInt(seq);

console.log("bid: " + bid + ",  seq: " + seq);
	if(seq == 0) {
		console.log("Deleting broadcast " + bid);
		// Delete DDB record
		dynamodb.deleteItem({
			TableName: config.DDB_BROADCAST_TABLE,
			Key: { bid: { S: bid }},
			ReturnValues: 'NONE'
		}, function(err, data) {
			console.log(util.inspect(err, { showHidden: true, depth: 10 }));
			if(err) callback(err);
			else callback();
		});	
	} else {
		callback();
		console.log("Only act on sequence 0");
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
    if(parts[0] == "test" && key != "test/")
    {
    	context.fail({success:false, error:'test file ignored'});
    }
    else if(parts.length == 2) {
    	process(bucket, key, parts[0], parts[1], function(err) {
    		if(err) context.fail({success:false, error:err});
    		else context.succeed({success: true});
    	});
    } else {
	    context.fail({success:false, error:'Invalid file name: ' + key});
    }
}
