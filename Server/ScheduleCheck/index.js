console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var moment = require('moment');
var config = require('./config.json');
var async = require('async');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();

function removeSchedule(sid, callback) {
	console.log("removeSchedule: ", sid);
	dynamodb.deleteItem({
		TableName: config.DDB_SCHEDULE_TABLE,
		Key: { sid: { S: sid }},
		ReturnValues: 'NONE'
	}, function(err, data) {
		console.log("removeSchedule err: " + util.inspect(err, { showHidden: true, depth: 10 }));
		if(err) callback(err);
		else callback();
	});	
}

function deleteExpiredSchedules(callback) {
	var now = moment().utc().format('X');

	dynamodb.scan({
		TableName: config.DDB_SCHEDULE_TABLE,
		ProjectionExpression: "sid, #type, #start, #to",
		FilterExpression: "(#type = :tsingle AND #start < :datenow) OR (#type = :trecurring AND #to < :datenow)",
		ExpressionAttributeNames: { "#type": "type",
									"#start": "start",
									"#to": "to" },
		ExpressionAttributeValues: { ":datenow": { "N": now },
									 ":tsingle": { "S": "single" },
									 ":trecurring": { "S": "recurring" } }
	}, function(err, data) {
		console.log("data: " + util.inspect(data, { showHidden: true, depth: 10 }));
		console.log("err: " + util.inspect(err, { showHidden: true, depth: 10 }));
		if(err) callback(err);
		else {
			if ('Items' in data) {
				console.log("Now " + now);
				async.eachSeries(data.Items, function(item, fn) {
					console.log(moment.unix(now).format("MM/DD/YYYY hh:mm:ss") + " " + item.sid.S + ": " + 
						item.type.S + " " + moment.unix(item.start.N).format("MM/DD/YYYY hh:mm:ss") + " " + moment.unix(item.to.N).format("MM/DD/YYYY hh:mm:ss"));
					var sid = item.sid.S;
					removeSchedule(sid, function(err) {
						if(err)	console.log("Error removing " + sid + ": " + err);						
						else console.log("Removed: " + sid);						
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

	deleteExpiredSchedules(function(err) {		
		if(err) context.fail(err);
		else context.succeed();
	});
}
