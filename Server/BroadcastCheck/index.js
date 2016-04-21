console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var moment = require('moment');
var config = require('./config.json');
var async = require('async');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();

function removeBroadcast(bid, callback) {
	console.log("removeBroadcast: ", bid);
	dynamodb.deleteItem({
		TableName: config.DDB_BROADCAST_TABLE,
		Key: { bid: { S: bid }},
		ReturnValues: 'NONE'
	}, function(err, data) {
		console.log("removeBroadcast err: " + util.inspect(err, { showHidden: true, depth: 10 }));
		if(err) callback(err);
		else callback();
	});	
}

function deleteExpiredBroadcasts(callback) {
	var cutoff = moment().subtract(1, "days").utc().format('X');

	dynamodb.scan({
		TableName: config.DDB_BROADCAST_TABLE,
		ProjectionExpression: "bid, #updated",
		FilterExpression: "#updated < :cutoff",
		ExpressionAttributeNames: { "#updated": "updated" },
		ExpressionAttributeValues: { ":cutoff": { "N": cutoff } }
	}, function(err, data) {
		console.log("data: " + util.inspect(data, { showHidden: true, depth: 10 }));
		console.log("err: " + util.inspect(err, { showHidden: true, depth: 10 }));
		if(err) callback(err);
		else {
			if ('Items' in data) {
				console.log("cutoff " + cutoff);
				async.eachSeries(data.Items, function(item, fn) {
					console.log(moment.unix(cutoff).format("MM/DD/YYYY hh:mm:ss") + " " + item.bid.S + ": " + 
						moment.unix(item.updated.N).format("MM/DD/YYYY hh:mm:ss"));
					var bid = item.bid.S;
					removeBroadcast(bid, function(err) {
						if(err)	console.log("Error removing " + bid + ": " + err);						
						else console.log("Removed: " + bid);						
						fn();
					});
				}, function(err) {
					callback();
				});
			}
		}
	});
}

exports.handler = function(event, context) {
	console.log("event: " + util.inspect(event));

	deleteExpiredBroadcasts(function(err) {		
		if(err) context.fail(err);
		else context.succeed();
	});
}
